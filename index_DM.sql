--Droping indexes to simulate "before" state
DROP INDEX IF EXISTS idx_bankaccount_user;
DROP INDEX IF EXISTS idx_transactions_account;
DROP INDEX IF EXISTS idx_transactions_date;
DROP INDEX IF EXISTS idx_investment_user;
DROP INDEX IF EXISTS idx_conversation_user;

-- 1. Sequential scan expected (no index)
EXPLAIN ANALYZE
SELECT * FROM BankAccount WHERE user_id = 24;

-- 2. Sequential scan expected
EXPLAIN ANALYZE
SELECT * FROM Transactions WHERE account_id = 347;

-- 3. Sequential scan expected
EXPLAIN ANALYZE
SELECT * FROM Transactions WHERE transaction_date >= '2025-02-01';

-- 4. Sequential scan expected
EXPLAIN ANALYZE
SELECT * FROM Investment WHERE user_id = 678;

-- 5. Sequential scan expected (or PK scan if interaction_id is PK)
EXPLAIN ANALYZE
SELECT * FROM AIConversation WHERE interaction_id = 405;


CREATE INDEX idx_bankaccount_user ON BankAccount(user_id);
CREATE INDEX idx_transactions_account ON Transactions(account_id);
CREATE INDEX idx_transactions_date ON Transactions(transaction_date);
CREATE INDEX idx_investment_user ON Investment(user_id);
CREATE INDEX idx_conversation_user ON AIConversation(interaction_id);

-- 1. Index Scan expected on idx_bankaccount_user
EXPLAIN ANALYZE
SELECT * FROM BankAccount WHERE user_id = 100;

-- 2. Index Scan expected on idx_transactions_account
EXPLAIN ANALYZE
SELECT * FROM Transactions WHERE account_id = 314;

-- 3. Index Scan / Bitmap Index Scan expected on idx_transactions_date
EXPLAIN ANALYZE
SELECT * FROM Transactions WHERE transaction_date >= '2025-11-17';

-- 4. Index Scan expected on idx_investment_user
EXPLAIN ANALYZE
SELECT * FROM Investment WHERE user_id = 521;

-- 5. Index Scan expected on idx_conversation_user
EXPLAIN ANALYZE
SELECT * FROM AIConversation WHERE interaction_id = 301;
