# Personal Finance Management Database System

## Overview

This project is a **Personal Finance Management Database System** designed to help users manage their financial activities efficiently. The system supports features such as:

* User account management
* Budget tracking
* Financial goals
* Transactions and transaction categories
* Investments and loans
* Notifications and AI conversations
* Banking account management

The project was built using **PostgreSQL** and includes:

* Database schema design
* SQL scripts for DDL, DML, DQL
* Functions and triggers
* Index optimization
* ERD diagrams
* Sample/generated data

---

## Project Structure

```bash
Database Personal Finance Management/
│
├── ERD/
│   ├── erd_PM.drawio
│   └── erd_PM.drawio.png
│
├── SQL/
│   ├── ddl_PM.sql
│   ├── dml_PM.sql
│   ├── dql_PM.sql
│   ├── functions_triggers_PM.sql
│   ├── index_DM.sql
│   └── text_file_for_dml.txt
│
├── Data(Faker in Python)_PM.ipynb
├── DB_data.zip
├── Project Description - Copy.pdf
└── Reflective_report.pdf
```

---

## Features

### User Management

* Store user profiles and authentication information
* Track account creation and login status

### Banking & Transactions

* Create and manage bank accounts
* Record deposits, withdrawals, and transactions
* Categorize financial activities

### Budgeting

* Create budgets
* Monitor spending
* Compare expenses against planned budgets

### Financial Goals

* Set savings goals
* Track progress percentages
* Monitor overdue goals

### Investments & Loans

* Track investments and investment risk levels
* Store loan information and repayment details

### Notifications & Messaging

* Notification system for users
* AI conversation/message support

### Database Optimization

* Indexes for query optimization
* Functions and triggers for automation
* Performance testing using `EXPLAIN ANALYZE`

---

## Database Schema

The system contains several related tables including:

* `Users`
* `BankAccount`
* `Budget`
* `FinancialGoal`
* `Loan`
* `Investment`
* `Transactions`
* `TransactionCategory`
* `Notification`
* `AIConversation`
* `Messages`
* `UserNotification`

Relationships are visualized in the ERD located in the `ERD/` folder.

---

## Technologies Used

* **PostgreSQL**
* **SQL**
* **Python (Faker Library)** for generating sample data
* **Draw.io** for ERD design
* **Jupyter Notebook**

---

## SQL Files Description

### `ddl_PM.sql`

Contains all table creation statements and database schema definitions.

### `dml_PM.sql`

Contains commands for importing and inserting sample/generated data into the database.

### `dql_PM.sql`

Contains analytical and reporting queries such as:

* Goal completion tracking
* Overdue goals
* Investment analysis
* Financial summaries

### `functions_triggers_PM.sql`

Contains:

* Functions
* Triggers
* Sequence management
* Automation logic

### `index_DM.sql`

Contains index creation and performance optimization queries using `EXPLAIN ANALYZE`.

---

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/personal-finance-management.git
cd personal-finance-management
```

### 2. Create Database

```sql
CREATE DATABASE personal_finance_management;
```

### 3. Run DDL Script

```bash
psql -U postgres -d personal_finance_management -f ddl_PM.sql
```

### 4. Import Data

Update file paths inside `dml_PM.sql` if necessary, then run:

```bash
psql -U postgres -d personal_finance_management -f dml_PM.sql
```

### 5. Run Queries and Optimization Scripts

```bash
psql -U postgres -d personal_finance_management -f dql_PM.sql
psql -U postgres -d personal_finance_management -f functions_triggers_PM.sql
psql -U postgres -d personal_finance_management -f index_DM.sql
```

---

## Example Queries

### Goal Completion Percentage

```sql
SELECT goal_name,
       target_amount,
       current_amount,
       ROUND((current_amount::NUMERIC / target_amount) * 100, 1) AS completion_pct
FROM financialgoal;
```

### Overdue Goals

```sql
SELECT goal_name,
       CURRENT_DATE - deadline AS days_overdue
FROM financialgoal
WHERE status != 'completed';
```

---

## Learning Outcomes

Through this project, the following concepts were practiced:

* Relational database design
* SQL query writing
* Normalization
* Indexing and optimization
* Database automation using triggers/functions
* Data generation using Python
* Analytical querying

---

## Future Improvements

* Add a frontend web interface
* Integrate real-time financial APIs
* Add user authentication encryption
* Implement dashboards and visual analytics
* Improve AI financial recommendation features

---

## Author

Lucy — Data Science Student at the American University of Armenia.

---

## License

This project is intended for educational and academic purposes.
