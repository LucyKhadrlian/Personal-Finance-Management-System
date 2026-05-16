
SELECT setval(pg_get_serial_sequence('users', 'user_id'), MAX(user_id)) FROM Users;
SELECT setval(pg_get_serial_sequence('bankaccount', 'account_id'), MAX(account_id)) FROM BankAccount;
SELECT setval(pg_get_serial_sequence('notification', 'notification_id'), MAX(notification_id)) FROM Notification;
SELECT setval(pg_get_serial_sequence('budget', 'budget_id'), MAX(budget_id)) FROM Budget;
SELECT setval(pg_get_serial_sequence('financialgoal', 'goal_id'), MAX(goal_id)) FROM FinancialGoal;
SELECT setval(pg_get_serial_sequence('loan', 'loan_id'), MAX(loan_id)) FROM Loan;
SELECT setval(pg_get_serial_sequence('investment', 'investment_id'), MAX(investment_id)) FROM Investment;
SELECT setval(pg_get_serial_sequence('transactions', 'transaction_id'), MAX(transaction_id)) FROM Transactions;
SELECT setval(pg_get_serial_sequence('transactioncategory', 'category_id'), MAX(category_id)) FROM TransactionCategory;
--TOOK THESE SAMPLE CODES TO BE ABLE TO INSERT WITHOUT SPECIFYING IDs (as they are SERIAL)

--TRIGGER 1: Creates Bank account (with checking type) for the new user we add in Users table

DROP TRIGGER create_df_account_t ON Users;
DROP FUNCTION create_df_account_f();

CREATE OR REPLACE FUNCTION create_df_account_f()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO BankAccount (user_id, account_name, account_type, balance, currency)
    VALUES (NEW.user_id, 'My Checking Account', 'Checking', 0, 'USD');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER create_df_account_t
AFTER INSERT ON Users
FOR EACH ROW
EXECUTE FUNCTION create_df_account_f();

--TESTING IT
INSERT INTO Users (first_name, surname, email, phone, passwords, nationality, status)
VALUES ('Ani', 'Grigoryan', 'anigrigoryan123@gmail.com', '555-999', 'pass125', 'Armenian', 'verified');

SELECT u.user_id, u.first_name, u.email, b.account_id, b.account_name, b.account_type, b.balance, b.currency
FROM Users u
JOIN BankAccount b ON u.user_id = b.user_id
WHERE u.email = 'anigrigoryan123@gmail.com';

-- TRIGGER 2: When we insert a transaction, it finds the matching budget and adds the amount to it, 
--changes the account balances, and sends notification if the amount_limit is exceeded

CREATE OR REPLACE FUNCTION update_budget_f()
RETURNS TRIGGER AS $$
DECLARE
    a_limit        INT;
    a_threshold    INT;
    a_user_id      INT;
    a_name         VARCHAR;
    a_consumed     INT;
BEGIN
    UPDATE Budget
    SET consumed_amount = consumed_amount + NEW.amount
    WHERE category_id = NEW.category_id
    AND status = 'active';

    UPDATE BankAccount
    SET balance = balance - NEW.amount
    WHERE account_id = NEW.account_id;

    UPDATE BankAccount
    SET balance = balance + NEW.amount
    WHERE account_id = NEW.reciever_id;
    RETURN NEW;

    SELECT amount_limit, alert_threshold, user_id, name, consumed_amount
    INTO a_limit, a_threshold, a_user_id, a_name, a_consumed
    FROM Budget
    WHERE category_id = NEW.category_id AND status = 'active';

    IF a_consumed >= a_limit THEN
        INSERT INTO Notification (user_id, title, messages)
        VALUES (a_user_id, 'Budget Limit Reached', 'You have gone over your budget ' || a_name || '');
    ELSIF (a_consumed*100 / a_limit) >= a_threshold THEN
        INSERT INTO Notification (user_id, title, messages)
        VALUES (a_user_id, 'Budget Warning', 'You get close to your' ||a_name|| 'budget limit');
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_budget_t
AFTER INSERT ON Transactions
FOR EACH ROW
EXECUTE FUNCTION update_budget_f();

--TESTING IT
SELECT budget_id, name, category_id, amount_limit, alert_threshold, consumed_amount, user_id
FROM Budget
WHERE status = 'active';

SELECT account_id, user_id, balance 
FROM BankAccount
WHERE user_id = 15;

INSERT INTO Transactions (account_id, reciever_id, category_id, amount, status, description)
VALUES (41, 85, 5, 700, 'completed', 'Rent');

SELECT budget_id, name, amount_limit, consumed_amount
FROM Budget
WHERE budget_id = 43;

SELECT account_id, balance
FROM bankaccount
WHERE account_id = 41 OR account_id = 85;

SELECT title, messages FROM Notification
WHERE user_id = 5
ORDER BY notification_id DESC LIMIT 1;


--TRIGGER 3: Raises an error for transactions that exceed the amount in balance 
CREATE OR REPLACE FUNCTION block_balance_f()
RETURNS TRIGGER AS $$
DECLARE
    current_balance INT;
BEGIN
    SELECT balance INTO current_balance
    FROM BankAccount
    WHERE account_id = NEW.account_id;
	
    IF current_balance - NEW.amount < 0 THEN
        RAISE EXCEPTION 'Insufficient balance. Your balance is % but you tried to send %.', current_balance, NEW.amount;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER block_balance_t
BEFORE INSERT ON Transactions
FOR EACH ROW
EXECUTE FUNCTION block_balance_f();

--TESTING IT
SELECT balance, account_id
FROM BankAccount 
WHERE user_id = 74;

INSERT INTO Transactions (account_id, reciever_id, amount, status, description)
VALUES (198, 29, 80000, 'completed', 'Loan');

--TRIGGER 4: When we do transaction, if the principal amount is paid then change status 'paid'
--send notification that the loan is paid, or loan is received if the paid amount does not cover the loan

CREATE OR REPLACE FUNCTION update_loan_status_f()
RETURNS TRIGGER AS $$
DECLARE
    a_total_paid    INT;
    a_principal     INT;
    a_remaining     INT;
    a_user_id       INT;
BEGIN
    IF NEW.loan_id IS NOT NULL THEN
        SELECT principal_amount, user_id
        INTO a_principal, a_user_id
        FROM Loan
        WHERE loan_id = NEW.loan_id;

        SELECT SUM(amount) INTO a_total_paid
        FROM Transactions
        WHERE loan_id = NEW.loan_id;

        a_total_paid := a_total_paid + NEW.amount;
        a_remaining := a_principal - a_total_paid;
        RAISE NOTICE 'Remaining=%', a_remaining;

        IF a_remaining <= 0 THEN
            UPDATE Loan SET status = 'paid'
            WHERE loan_id = NEW.loan_id;

            INSERT INTO Notification (user_id, title, messages)
            VALUES (a_user_id, 'Loan Paid', 'Your loan has been fully paid');
        ELSE
            INSERT INTO Notification (user_id, title, messages)
            VALUES (a_user_id, 'Loan Payment Received', 'You paid ' || NEW.amount || ', remaining balance is ' || a_remaining || '');
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_loan_status_t
AFTER INSERT ON Transactions
FOR EACH ROW
EXECUTE FUNCTION update_loan_status_f();


--TESTING IT
SELECT loan_id, user_id, lender_name, principal_amount, status
FROM Loan
WHERE status = 'active';

SELECT account_id, user_id, balance
FROM BankAccount
WHERE user_id = 10;

SELECT SUM(amount) AS already_paid
FROM Transactions
WHERE loan_id = 15;

SELECT principal_amount
FROM loan
WHERE loan_id = 15;

INSERT INTO Transactions (account_id, reciever_id, loan_id, category_id, amount, status, description)
VALUES (28, 8, 15, NULL, 1000, 'completed', 'Partial loan payment');

SELECT title, messages FROM Notification
WHERE user_id = 10
ORDER BY notification_id DESC LIMIT 1;

SELECT loan_id, user_id, lender_name, principal_amount, status
FROM Loan
WHERE user_id = 10;


--TRIGGER 5: Every time I update the current amount of the goal, we check if we completed out goal
CREATE OR REPLACE FUNCTION goal_completion_f()
RETURNS TRIGGER AS $$
BEGIN
    NEW.progress_rate := (NEW.current_amount * 100) / NEW.target_amount;
    IF NEW.current_amount >= NEW.target_amount THEN
        NEW.status := 'completed';
        INSERT INTO Notification (user_id, title, messages)
        VALUES (NEW.user_id, 'Goal Completed', 'You have reached your financial goal');
    END IF;
	
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER goal_completion_t
BEFORE UPDATE OF current_amount ON FinancialGoal
FOR EACH ROW
EXECUTE FUNCTION goal_completion_f();

--TESTING IT
INSERT INTO FinancialGoal (user_id, goal_name, goal_type, target_amount, current_amount, status)
VALUES (1001, 'Buy a Car', 'savings', 10000, 0, 'active');

SELECT goal_id, user_id, goal_name, goal_type, target_amount, current_amount,progress_rate, status
FROM financialgoal
WHERE user_id = 1001;

UPDATE FinancialGoal
SET current_amount = 10000
WHERE goal_id = 3458;

SELECT title, messages
FROM Notification
WHERE user_id = 1001
ORDER BY notification_id DESC LIMIT 1;



--FUNCTIONS WITHOUT TRIGGERS

--1: Returns the difference between expenses and earnings within two dates

DROP FUNCTION get_net_cashflow(f_user_id INT, f_start DATE, f_end DATE);

CREATE OR REPLACE FUNCTION get_net_cashflow(f_user_id INT, f_start DATE, f_end DATE)
RETURNS INT AS $$
DECLARE
    a_income   INT;
    a_expenses INT;
BEGIN

    SELECT SUM(t.amount) INTO a_income
    FROM Transactions t
    JOIN BankAccount b ON t.reciever_id = b.account_id
    WHERE b.user_id = f_user_id
    AND t.transaction_date BETWEEN f_start AND f_end;

    SELECT SUM(t.amount) INTO a_expenses
    FROM Transactions t
    JOIN BankAccount b ON t.account_id = b.account_id
    WHERE b.user_id = f_user_id
    AND t.transaction_date BETWEEN f_start AND f_end;

    IF a_income IS NULL THEN 
		a_income := 0; 
	END IF;
    IF a_expenses IS NULL THEN
		a_expenses := 0; 
	END IF;

    RETURN a_income - a_expenses;
END;
$$ LANGUAGE plpgsql;

SELECT get_net_cashflow(45, '2024-01-01', '2024-12-31');


--2: We get the principal amount then the transactions under a specific loan id, 
-- then compute the remaining amount, which was a derived attibute
CREATE OR REPLACE FUNCTION get_loan_remaining(f_loan_id INT)
RETURNS INT AS $$
DECLARE
    a_principal  INT;
    a_total_paid INT;
BEGIN
    SELECT principal_amount INTO a_principal
    FROM Loan WHERE loan_id = f_loan_id;

    SELECT SUM(amount) INTO a_total_paid
    FROM Transactions WHERE loan_id = f_loan_id;

    IF a_total_paid IS NULL THEN
		a_total_paid := 0; 
	END IF;

    RETURN a_principal - a_total_paid;
END;
$$ LANGUAGE plpgsql;

SELECT get_loan_remaining(19);

-- 3: We get the how much balance the user have

CREATE OR REPLACE FUNCTION get_total_balance(f_user_id INT)
RETURNS INT AS $$
DECLARE
    a_total INT;
BEGIN

    SELECT SUM(balance) INTO a_total
    FROM BankAccount
    WHERE user_id = f_user_id;
    IF a_total IS NULL THEN
		a_total := 0; 
	END IF;
    RETURN a_total;
END;
$$ LANGUAGE plpgsql;

SELECT get_total_balance(45);






