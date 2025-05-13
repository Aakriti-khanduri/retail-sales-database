# retail-sales-database
# 🛒 Retail Sales Database

This project models a retail sales environment using three interconnected datasets:
📊 Dataset Source: [Kaggle - Retail Sales Data](https://www.kaggle.com/datasets/svbstan/sales-product-and-customer-insight-repository?select=customer_profile_dataset.csv)

- customer_profile_dataset
- products_dataset_1
- purchase_history_dataset

## 🗃️ Datasets

### 1. customer_profile_dataset
Stores customer information:
- customer_id (PK)
- first_name, last_name, gender, date_of_birth, email, phone_number
- sign_up_time, sign_up_date, address, city, state, zip_code

### 2. products_dataset_1
Contains product details:
- product_id (PK)
- product_name, brand, category, price_per_unit

### 3. purchase_history_dataset
Records customer purchases:
- purchase_id (PK)
- customer_id (FK), product_id (FK)
- purchase_date_m, purchase_time_m, quantity, total_amount

## 🔗 Relationships

- Each customer can make multiple purchases.
- Each product can appear in multiple purchases.
- `purchase_history_dataset` acts as a fact table connecting customers and products.

**Key Points**:
- `customer_profile_dataset` and `products_dataset_1` are parent tables.
- `purchase_history_dataset` links both via foreign keys.
- `total_amount` is calculated based on the quantity and product's unit price.
