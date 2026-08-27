import pandas as pd

# ---------------------------------------------------------
# FILE PATHS
# ---------------------------------------------------------

RAW_FILE = "data/raw/online_retail_II.xlsx"
CLEAN_SALES_OUTPUT = "data/processed/clean_sales.csv"
CUSTOMER_SALES_OUTPUT = "data/processed/customer_sales.csv"


# ---------------------------------------------------------
# LOAD RAW DATA
# ---------------------------------------------------------

print("Loading raw datasets...")

df_2009_2010 = pd.read_excel(
    RAW_FILE,
    sheet_name="Year 2009-2010"
)

df_2010_2011 = pd.read_excel(
    RAW_FILE,
    sheet_name="Year 2010-2011"
)

# Combine both years
df = pd.concat(
    [df_2009_2010, df_2010_2011],
    ignore_index=True
)

print(f"Raw rows: {len(df):,}")


# ---------------------------------------------------------
# REMOVE EXACT DUPLICATES
# ---------------------------------------------------------

duplicate_count = df.duplicated().sum()

df = df.drop_duplicates().copy()

print(f"Duplicates removed: {duplicate_count:,}")


# ---------------------------------------------------------
# CREATE CLEAN COMPLETED-SALES DATASET
# ---------------------------------------------------------

# Completed sales must:
# - Have a positive quantity
# - Have a positive price
# - Not be a cancelled invoice (cancelled invoices begin with C)
#
# This excludes cancellations/returns, stock adjustments,
# zero-price operational records and negative-price
# accounting adjustments from completed-sales KPIs.

clean_sales = df[
    (df["Quantity"] > 0)
    & (df["Price"] > 0)
    & (~df["Invoice"].astype(str).str.startswith("C"))
].copy()


# ---------------------------------------------------------
# CREATE REVENUE FIELD
# ---------------------------------------------------------

clean_sales["Price"] = clean_sales["Price"].round(4)

clean_sales["Revenue"] = (
    clean_sales["Quantity"] * clean_sales["Price"]
).round(4)


# ---------------------------------------------------------
# CREATE CUSTOMER ANALYSIS DATASET
# ---------------------------------------------------------

# Transactions without Customer ID remain in clean_sales
# because they are still useful for overall sales,
# product and geographic analysis.
#
# Customer-level analysis requires an identifiable customer.

customer_sales = clean_sales[
    clean_sales["Customer ID"].notna()
].copy()

customer_sales["Customer ID"] = (
    customer_sales["Customer ID"].astype(int)
)


# ---------------------------------------------------------
# EXPORT PROCESSED DATASETS
# ---------------------------------------------------------

clean_sales.to_csv(
    CLEAN_SALES_OUTPUT,
    index=False
)

customer_sales.to_csv(
    CUSTOMER_SALES_OUTPUT,
    index=False
)


# ---------------------------------------------------------
# VALIDATION SUMMARY
# ---------------------------------------------------------

print("\n--- CLEANING SUMMARY ---")

print(f"Raw rows: {1_067_371:,}")
print(f"Rows after duplicate removal: {len(df):,}")
print(f"Clean sales rows: {len(clean_sales):,}")
print(f"Customer analysis rows: {len(customer_sales):,}")

print(
    f"Unique identified customers: "
    f"{customer_sales['Customer ID'].nunique():,}"
)

print(
    f"Clean sales date range: "
    f"{clean_sales['InvoiceDate'].min()} "
    f"to {clean_sales['InvoiceDate'].max()}"
)

print(
    f"Total clean sales revenue: "
    f"£{clean_sales['Revenue'].sum():,.2f}"
)

print("\nMissing values in clean sales:")
print(clean_sales.isnull().sum())

print("\nProcessed datasets exported successfully:")
print(CLEAN_SALES_OUTPUT)
print(CUSTOMER_SALES_OUTPUT)