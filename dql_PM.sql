--Goal completion percentage--
SELECT goal_name,
       target_amount,
       current_amount,
       ROUND((current_amount::NUMERIC / target_amount) * 100, 1) AS completion_pct,
       deadline,
       status
FROM financialgoal
WHERE user_id = 24
ORDER BY completion_pct DESC;

--Overdue(past deadline, not completed)--   
SELECT goal_name, target_amount, current_amount, deadline,
       CURRENT_DATE - deadline AS days_overdue
FROM financialgoal
WHERE user_id = 19
AND status != 'completed'
ORDER BY days_overdue DESC;

--Goals by priority with remaining amount--
SELECT goal_name, priority, status,
       target_amount - current_amount AS remaining,
       deadline
FROM financialgoal
WHERE user_id = 9
AND status != 'completed'
ORDER BY priority ASC, deadline ASC; // descending 



----Investments worth more than ALL deposits----
SELECT investment_id, investment_type,
       amount_invested, risk_level, status
FROM investment
WHERE amount_invested > ALL (
    SELECT amount_invested
    FROM investment
    WHERE investment_type = 'deposit'
      AND user_id = 6
)
AND user_id = 2
AND investment_type != 'deposit';

----Identifies any tracked investment performing better than every bond tracking entry---
SELECT it.tracking_id, it.investment_id,
       it.tracked_value, it.change_percent, it.dates
FROM investmenttracking it
JOIN investment i ON i.investment_id = it.investment_id
WHERE i.user_id = '12'
  AND it.change_percent > ALL (
    SELECT it2.change_percent
    FROM investmenttracking it2
    JOIN investment i2 ON i2.investment_id = it2.investment_id
    WHERE i2.investment_type = 'bond'
      AND i2.user_id = '12'
  )
ORDER BY it.change_percent DESC;

--All active investments with type---
SELECT i.investment_id, i.investment_type,
       i.amount_invested, i.expected_return,
       i.risk_level, i.purchase_date
FROM investment i
WHERE i.user_id = '12'
  AND i.status = 'active'
ORDER BY i.purchase_date DESC;


--Shows all users with active investments
SELECT user_id, first_name, surname, email
FROM users
WHERE user_id IN (
    SELECT user_id
    FROM investment
    WHERE status = 'active'
)
ORDER BY surname;


--investmets tracked in last 7 days
SELECT investment_id, investment_type,
       amount_invested, status
FROM investment
WHERE investment_id IN (
    SELECT investment_id
    FROM investmenttracking
    WHERE dates >= CURRENT_DATE - INTERVAL '7 days'// 
)
AND user_id = 1;

---goals belong to verified accounts
SELECT goal_name, target_amount, current_amount,
       deadline, status
FROM financialgoal
WHERE user_id IN (
    SELECT user_id
    FROM users
    WHERE status = 'verified'
)
ORDER BY deadline ASC;

---Conversations that have at least one message----
SELECT DISTINCT ai.interaction_id,
       ai.conversation_name,
       ai.priority,
       ai.conversation_date
FROM aiconversation ai
JOIN messages m
  ON m.interaction_id = ai.interaction_id
WHERE ai.user_id = 9
ORDER BY ai.conversation_date DESC;

---Tracking negative entrry---
SELECT i.investment_id, i.investment_type,
       i.amount_invested, i.risk_level
FROM investment i
WHERE i.user_id = 6
  AND EXISTS (
    SELECT 1
    FROM investmenttracking it
    WHERE it.investment_id = i.investment_id
      AND it.change_percent < 0
  );

--Show all deposits--
SELECT i.amount_invested, d.bank_name, d.interest_rate, d.maturity_date
FROM deposit d
JOIN investment i ON i.investment_id = d.investment_id
WHERE i.user_id = 1;

---Investment portfolio summary by type
SELECT investment_type,
       COUNT(*) AS total_investments,
       SUM(amount_invested) AS total_invested,
       SUM(expected_return) AS total_expected_return
FROM investment
WHERE user_id = 1
  AND status = 'active'
GROUP BY investment_type
ORDER BY total_invested DESC;


--Best performing stock--
SELECT s.stock_name, s.current_price, s.number_of_shares,
    (s.current_price-i.amount_invested) * s.number_of_shares AS total_value
FROM stocks s
JOIN investment i ON i.investment_id = s.investment_id
WHERE i.user_id = 6 AND i.status = 'active'
ORDER BY total_value DESC
LIMIT 1;


---All stocks with total portfolio value---
SELECT s.stock_name,
       s.number_of_shares,
       s.current_price,
       s.dividend_yield,
       i.amount_invested,
       s.current_price * s.number_of_shares AS market_value,
       (s.current_price * s.number_of_shares) - i.amount_invested AS unrealized_pnl
FROM stocks s
JOIN investment i ON i.investment_id = s.investment_id
WHERE i.user_id = 758
  AND i.status = 'active'
ORDER BY market_value DESC;

---Investments with negative change (losing value)---
SELECT i.investment_id, i.investment_type,
       it.tracked_value, it.change_percent, it.dates
FROM investmenttracking it
JOIN investment i ON i.investment_id = it.investment_id
WHERE i.user_id = 69
  AND it.change_percent < 0
ORDER BY it.change_percent ASC;

---Tracking history for a specific investment---
SELECT tracked_value, change_percent, dates
FROM investmenttracking
WHERE investment_id = 96
ORDER BY dates ASC;

----Average change % per investment type---
SELECT i.investment_type,
       ROUND(AVG(it.change_percent), 2) AS avg_change_pct,
       MIN(it.change_percent) AS worst,
       MAX(it.change_percent) AS best
FROM investmenttracking it
JOIN investment i ON i.investment_id = it.investment_id
WHERE i.user_id = 75
GROUP BY i.investment_type
ORDER BY avg_change_pct DESC;

--Show all conversations
SELECT interaction_id, conversation_name, priority, conversation_date
FROM aiconversation
WHERE user_id = 9
ORDER BY conversation_date DESC;

--Show pinned conversations--
SELECT interaction_id, conversation_name, conversation_date
FROM aiconversation
WHERE user_id = 156 AND priority = 'pinned'
ORDER BY conversation_date DESC;

--Message count per conversation--
SELECT ac.conversation_name, COUNT(m.message_id) AS total_messages
FROM aiconversation ac
JOIN messages m ON m.interaction_id = ac.interaction_id
WHERE ac.user_id = 987
GROUP BY ac.conversation_name;

---Last message in each conversation---
SELECT ac.conversation_name, m.user_query, m.assistant_response
FROM aiconversation ac
JOIN messages m ON m.interaction_id = ac.interaction_id
WHERE ac.user_id = 65
  AND m.message_id = (
    SELECT MAX(m2.message_id)
    FROM messages m2
    WHERE m2.interaction_id = ac.interaction_id
  )
ORDER BY ac.conversation_date DESC;

----Search conversations by keyword---
SELECT ac.conversation_name, m.user_query, m.assistant_response
FROM messages m
JOIN aiconversation ac ON ac.interaction_id = m.interaction_id
WHERE ac.user_id = 84
  AND (
    m.user_query ILIKE '%budget%'
    OR m.assistant_response ILIKE '%budget%'
  )
ORDER BY ac.conversation_date DESC;

--Most spent category--
SELECT tc.category_name, SUM(t.amount) AS total_spent
FROM transactions t
JOIN transactioncategory tc ON tc.category_id = t.category_id
JOIN bankaccount ba ON ba.account_id = t.account_id
WHERE ba.user_id = 300 AND t.status = 'completed'
GROUP BY tc.category_name
ORDER BY total_spent DESC
LIMIT 1;

-- Show a conversation
SELECT user_query, assistant_response
FROM messages
WHERE interaction_id = 13
GROUP BY interaction_id, message_id, user_query, assistant_response
ORDER BY message_id;

-- total balance across all bankaccounts
SELECT SUM(balance)
FROM bankaccount
GROUP BY user_id;

-- latest transactions (IN & OUT)
SELECT user_id, MAX(created_at), type, amount
FROM transactions t
INNER JOIN bankaccount b ON b.account_id = t.account_id
WHERE status = 'completed'
GROUP BY user_id, type
ORDER BY created_at DESC
LIMIT 1;

-- Last Month's Spendings
SELECT user_id, SUM(amount)
FROM transactions t
INNER JOIN bankaccount b ON b.account_id = t.account_id
WHERE status = 'completed' AND type = 'spending' AND created_at BETWEEN '...' AND '...'
GROUP BY user_id;

-- Last Month's Earnings
SELECT user_id, SUM(amount)
FROM transactions t
JOIN bankaccount b ON b.account_id = t.account_id
WHERE status = 'completed' AND type = 'earning' AND created_at BETWEEN '...' AND '...'
GROUP BY user_id;

-- Show transactions belonging to X category
SELECT transaction_id, account_id, category_name
FROM transactions t
Join transactioncategory tc on tc.category_id = t.category_id
WHERE t.category_id = 2 AND status = 'completed';

-- Show cancelled transactions
SELECT transaction_id, account_id
FROM transactions t
WHERE status = 'cancelled';

-- Show certain bankaccount
SELECT *
FROM bankaccount
WHERE account_id = '142';

-- Show all categories
SELECT c.category_id, c.category_name, t.transaction_id, t.amount
FROM transactions t
RIGHT JOIN transactioncategory c ON t.category_id = c.category_id
ORDER BY c.category_id;

-- Show 30 latest notifications
Select *
FROM notification
ORDER BY send_date DESC
LIMIT 30;

-- Show all budgets
SELECT b.name, b.start_date, b.status, c.category_name, b.amount_limit as target_amount, b.end_date as deadline
FROM budget b
JOIN transactioncategory c ON c.category_id = b.category_id
WHERE user_id = 128;

-- Show all active budgets
SELECT b.name, b.start_date, b.status, c.category_name, b.amount_limit as target_amount, b.end_date as deadline
FROM budget b
JOIN transactioncategory c ON c.category_id = b.category_id
WHERE user_id = 10 AND b.status = 'active';

-- Show all loans
SELECT *
FROM loan
WHERE user_id = 789;

-- Show all loan payments
SELECT *
FROM loan l
JOIN bankaccount b ON l.user_id = b.user_id
WHERE b.user_id = 789;

-- Show current loans, with due date and lender name
SELECT principal_amount, status, due_date, lender_name
FROM loan
WHERE user_id = 789 AND status IN ('active', 'overdue');

-- Show info of all bought stocks
SELECT i.investment_id, s.stock_name, s.current_price, s.number_of_shares, i.amount_invested
FROM stocks s
JOIN Investment i ON i.investment_id = s.investment_id
WHERE user_id = 856
GROUP BY i.investment_id, stock_name, current_price, number_of_shares, amount_invested;

-- Show info of all owned bonds
SELECT i.investment_id, b.maturity_date, b.coupon_frequency, b.bond_type, i.amount_invested
FROM bonds b
JOIN Investment i ON i.investment_id = b.investment_id
WHERE user_id = 43
GROUP BY i.investment_id, b.maturity_date, b.coupon_frequency, b.bond_type, i.amount_invested;

-- Show budgets that are over the limit
SELECT c.category_name
FROM transactioncategory c
WHERE EXISTS (
    SELECT 1
    FROM transactions t
    JOIN budget b ON t.category_id = b.category_id
    WHERE t.category_id = c.category_id and t.type = 'spending'
    GROUP BY t.category_id, b.amount_limit
    HAVING SUM(t.amount) > b.amount_limit
);

-- Show users with the highest balance
SELECT user_id, SUM(balance) AS total_balance
FROM bankaccount
GROUP BY user_id
ORDER BY total_balance DESC
LIMIT 10;

-- Show users with multiple bankaccounts
SELECT a1.user_id, count(*) as accounts_count
FROM bankaccount a1
JOIN bankaccount a2 ON a1.user_id = a2.user_id AND a1.account_id < a2.account_id
GROUP BY a1.user_id
Order by count(*) DESC;

-- Show remaining amount
WITH
month_diff AS (
    SELECT  loan_id,
    (DATE_PART('year', due_date) - DATE_PART('year', start_date)) * 12 +
    (DATE_PART('month', due_date) - DATE_PART('month', start_date))
    AS months_passed
    FROM loan
)
SELECT
    l.loan_id,
    l.principal_amount,
    l.interest_rate,
    l.principal_amount - (l.principal_amount * l.interest_rate * md.months_passed) AS remaining_amount
FROM loan l
JOIN month_diff md ON l.loan_id = md.loan_id;

-- Shows spendings that exceed the avg of sending
SELECT *
FROM transactions
WHERE type = 'spending' AND account_id = 283 AND amount > (
    SELECT AVG(amount) FROM transactions
    WHERE type = 'spending' AND account_id = 283
);


  