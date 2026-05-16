DROP TABLE IF EXISTS UserNotification CASCADE;
DROP TABLE IF EXISTS Messages CASCADE;
DROP TABLE IF EXISTS InvestmentTracking CASCADE;
DROP TABLE IF EXISTS Transactions CASCADE;
DROP TABLE IF EXISTS Stocks CASCADE;
DROP TABLE IF EXISTS Bonds CASCADE;
DROP TABLE IF EXISTS Deposit CASCADE;
DROP TABLE IF EXISTS AIConversation CASCADE;
DROP TABLE IF EXISTS Notification CASCADE;
DROP TABLE IF EXISTS Investment CASCADE;
DROP TABLE IF EXISTS Loan CASCADE;
DROP TABLE IF EXISTS FinancialGoal CASCADE;
DROP TABLE IF EXISTS Budget CASCADE;
DROP TABLE IF EXISTS BankAccount CASCADE;
DROP TABLE IF EXISTS TransactionCategory CASCADE;
DROP TABLE IF EXISTS Users CASCADE;

CREATE TABLE Users (
    user_id SERIAL PRIMARY KEY,
    first_name VARCHAR(150) NOT NULL,
    surname VARCHAR(150) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    passwords VARCHAR(50),
    nationality TEXT,
    last_login_at VARCHAR(50),
    status VARCHAR(20) DEFAULT 'unverified',        
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_user_email CHECK (email LIKE '%@%'),
    CONSTRAINT chk_users_status CHECK (status IN ('verified','unverified'))
);

CREATE TABLE TransactionCategory (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(150) NOT NULL,
    description TEXT
);

CREATE TABLE BankAccount (
    account_id SERIAL PRIMARY KEY,
    user_id  INT NOT NULL,
    account_name VARCHAR(150),
    bank_name VARCHAR(150),
    balance INT DEFAULT 0,
    currency VARCHAR(10) DEFAULT 'USD',
    account_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_bankaccount_balance CHECK (balance >= 0),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE TABLE Budget (
    budget_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    category_id INT,
    amount_limit INT NOT NULL,
    alert_threshold INT NOT NULL,
    start_date DATE,
    end_date DATE,
    status VARCHAR(20),
    name VARCHAR(150),
	consumed_amount INT DEFAULT 0,
    CONSTRAINT chk_budget_limit CHECK (amount_limit > 0),
    CONSTRAINT chk_budget_status CHECK (status IN ('active','not active')),
    CONSTRAINT chk_alert_threshold_pct CHECK (alert_threshold BETWEEN 0 AND 100),
    CONSTRAINT chk_dates CHECK (end_date IS NULL OR start_date <= end_date),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES TransactionCategory(category_id) ON DELETE CASCADE
);

CREATE TABLE FinancialGoal (
    goal_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    goal_name VARCHAR(150),
    goal_type VARCHAR(50),
    target_amount INT,
    current_amount INT DEFAULT 0,
    progress_rate INT,
    priority INT,
    deadline DATE,
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_goal_target  CHECK (target_amount > 0),
    CONSTRAINT chk_goal_current CHECK (current_amount >= 0),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE TABLE Loan (
    loan_id SERIAL PRIMARY KEY,
    user_id  INT NOT NULL,
    lender_name VARCHAR(150),
    principal_amount INT,
    interest_rate INT,
    start_date DATE,
    due_date DATE,
    status VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE TABLE Investment (
    investment_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    investment_type VARCHAR(50) NOT NULL,
    amount_invested INT,
    expected_return INT,
    risk_level VARCHAR(50),
    purchase_date DATE,
    status VARCHAR(20),
    CONSTRAINT chk_investment_amount CHECK (amount_invested > 0),
    CONSTRAINT chk_investment_status CHECK (status IN ('active','sold','matured','cancelled')),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE TABLE Notification (
    notification_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    messages TEXT,
    is_read  BOOLEAN DEFAULT FALSE,
    send_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE TABLE AIConversation (
    interaction_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    conversation_name VARCHAR(150),
    priority VARCHAR(200),
    conversation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_priority CHECK (priority IN ('pinned','out pinned')),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE TABLE Transactions (
    transaction_id SERIAL PRIMARY KEY,
    account_id INT NOT NULL,
	loan_id INT,
    category_id INT,
    reciever_id INT NOT NULL,
    amount INT NOT NULL,
    status VARCHAR(20),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    exchange_rate INT,
	type VARCHAR(20),
    FOREIGN KEY (account_id)  REFERENCES BankAccount(account_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES TransactionCategory(category_id) ON DELETE CASCADE,
    FOREIGN KEY (reciever_id) REFERENCES BankAccount(account_id) ON DELETE CASCADE,
    FOREIGN KEY (loan_id) REFERENCES Loan(loan_id) ON DELETE CASCADE
);

CREATE TABLE Messages (
    message_id SERIAL PRIMARY KEY,
    interaction_id INT NOT NULL,
    user_query TEXT NOT NULL,
    assistant_response TEXT,
    FOREIGN KEY (interaction_id) REFERENCES AIConversation(interaction_id) ON DELETE CASCADE
);

CREATE TABLE InvestmentTracking (
    tracking_id SERIAL PRIMARY KEY,
    investment_id INT NOT NULL,
    tracked_value INT,
    change_percent INT,
    dates TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (investment_id) REFERENCES Investment(investment_id) ON DELETE CASCADE
);

CREATE TABLE Stocks (
    investment_id INT PRIMARY KEY,
    stock_name VARCHAR(150),
    current_price INT,
    dividend_yield INT,
    number_of_shares INT,
    CONSTRAINT chk_stocks_price CHECK (current_price >= 0),
    FOREIGN KEY (investment_id) REFERENCES Investment(investment_id) ON DELETE CASCADE
);

CREATE TABLE Bonds (
    investment_id INT PRIMARY KEY ,
    maturity_date DATE,
    coupon_frequency VARCHAR(50),
    bond_type VARCHAR(200),
    CONSTRAINT chk_bond_type CHECK (bond_type IN ('corporate','government')),
    FOREIGN KEY (investment_id) REFERENCES Investment(investment_id) ON DELETE CASCADE
);

CREATE TABLE Deposit (
    investment_id INT PRIMARY KEY,
    bank_name VARCHAR(150),
    interest_rate INT,
    maturity_date DATE,
    FOREIGN KEY (investment_id) REFERENCES Investment(investment_id) ON DELETE CASCADE
);

CREATE TABLE UserNotification (
    user_id INT NOT NULL,
    notification_id INT NOT NULL,
    PRIMARY KEY (user_id, notification_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (notification_id) REFERENCES Notification(notification_id) ON DELETE CASCADE
);      