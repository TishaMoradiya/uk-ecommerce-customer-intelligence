import pandas as pd

# ---------------------------------------------------------
# FILE PATH
# ---------------------------------------------------------

RAW_FILE = "data/raw/online_retail_II.xlsx"


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

df = pd.concat(
    [df_2009_2010, df_2010_2011],
    ignore_index=True
)


# ---------------------------------------------------------
# DATASET OVERVIEW
# ---------------------------------------------------------

print("\n--- DATASET OVERVIEW ---")

print(f"Year 2009-2010: {df_2009_2010.shape}")
print(f"Year 2010-2011: {df_2010_2011.shape}")
print(f"Combined dataset: {df.shape}")

print("\nColumns:")
print(df.columns.tolist())

print("\nData types:")
print(df.dtypes)


# ---------------------------------------------------------
# MISSING VALUES
# ---------------------------------------------------------

print("\n--- MISSING VALUES ---")

missing_values = df.isnull().sum()
missing_percentages = (
    df.isnull().sum() / len(df) * 100
).round(2)

print("\nMissing value counts:")
print(missing_values)

print("\nMissing value percentages:")
print(missing_percentages)


# ---------------------------------------------------------
# DUPLICATE RECORDS
# ---------------------------------------------------------

print("\n--- DUPLICATE RECORDS ---")

duplicate_count = df.duplicated().sum()
duplicate_percentage = round(
    duplicate_count / len(df) * 100,
    2
)

print(f"Duplicate rows: {duplicate_count:,}")
print(f"Duplicate percentage: {duplicate_percentage}%")


# ---------------------------------------------------------
# QUANTITY CHECKS
# ---------------------------------------------------------

print("\n--- QUANTITY CHECKS ---")

negative_quantity = df["Quantity"] < 0
zero_quantity = df["Quantity"] == 0

print(
    f"Negative quantities: "
    f"{negative_quantity.sum():,}"
)

print(
    f"Zero quantities: "
    f"{zero_quantity.sum():,}"
)


# ---------------------------------------------------------
# PRICE CHECKS
# ---------------------------------------------------------

print("\n--- PRICE CHECKS ---")

negative_price = df["Price"] < 0
zero_price = df["Price"] == 0

print(
    f"Negative prices: "
    f"{negative_price.sum():,}"
)

print(
    f"Zero prices: "
    f"{zero_price.sum():,}"
)


# ---------------------------------------------------------
# CANCELLED INVOICE CHECKS
# ---------------------------------------------------------

print("\n--- CANCELLED INVOICES ---")

cancelled_invoices = (
    df["Invoice"]
    .astype(str)
    .str.startswith("C")
)

print(
    f"Cancelled transaction rows: "
    f"{cancelled_invoices.sum():,}"
)

print(
    f"Cancelled transaction percentage: "
    f"{cancelled_invoices.mean() * 100:.2f}%"
)


# ---------------------------------------------------------
# NEGATIVE QUANTITY INVESTIGATION
# ---------------------------------------------------------

print("\n--- NEGATIVE QUANTITY INVESTIGATION ---")

negative_cancelled = (
    negative_quantity
    & cancelled_invoices
)

negative_non_cancelled = (
    negative_quantity
    & ~cancelled_invoices
)

cancelled_positive = (
    cancelled_invoices
    & (df["Quantity"] > 0)
)

print(
    "Negative quantity AND cancelled invoice:",
    f"{negative_cancelled.sum():,}"
)

print(
    "Negative quantity WITHOUT cancelled invoice:",
    f"{negative_non_cancelled.sum():,}"
)

print(
    "Cancelled invoice with positive quantity:",
    f"{cancelled_positive.sum():,}"
)


print(
    "\nMost common descriptions for "
    "negative non-cancelled records:"
)

print(
    df.loc[
        negative_non_cancelled,
        "Description"
    ]
    .value_counts(dropna=False)
    .head(30)
)


# ---------------------------------------------------------
# ZERO-PRICE INVESTIGATION
# ---------------------------------------------------------

print("\n--- ZERO-PRICE INVESTIGATION ---")

zero_price_records = df[
    df["Price"] == 0
]

print(
    f"Zero-price records: "
    f"{len(zero_price_records):,}"
)

print(
    "\nMost common descriptions "
    "for zero-price records:"
)

print(
    zero_price_records["Description"]
    .value_counts(dropna=False)
    .head(30)
)

print(
    "\nZero-price records with positive quantity:",
    f"{(zero_price_records['Quantity'] > 0).sum():,}"
)

print(
    "Zero-price records with negative quantity:",
    f"{(zero_price_records['Quantity'] < 0).sum():,}"
)

print(
    "Zero-price records with missing Customer ID:",
    f"{zero_price_records['Customer ID'].isna().sum():,}"
)


# ---------------------------------------------------------
# NEGATIVE-PRICE INVESTIGATION
# ---------------------------------------------------------

print("\n--- NEGATIVE-PRICE INVESTIGATION ---")

negative_price_records = df[
    df["Price"] < 0
]

print(
    negative_price_records[
        [
            "Invoice",
            "StockCode",
            "Description",
            "Quantity",
            "InvoiceDate",
            "Price",
            "Customer ID",
            "Country"
        ]
    ].to_string(index=False)
)


# ---------------------------------------------------------
# AUDIT SUMMARY
# ---------------------------------------------------------

print("\n--- DATA QUALITY AUDIT SUMMARY ---")

print(f"Total rows: {len(df):,}")
print(
    f"Missing Customer IDs: "
    f"{df['Customer ID'].isna().sum():,}"
)

print(
    f"Missing descriptions: "
    f"{df['Description'].isna().sum():,}"
)

print(
    f"Exact duplicate rows: "
    f"{duplicate_count:,}"
)

print(
    f"Cancelled transaction rows: "
    f"{cancelled_invoices.sum():,}"
)

print(
    f"Negative non-cancelled quantities: "
    f"{negative_non_cancelled.sum():,}"
)

print(
    f"Zero-price records: "
    f"{zero_price.sum():,}"
)

print(
    f"Negative-price records: "
    f"{negative_price.sum():,}"
)

print(
    "\nAudit complete. "
    "No data was modified by this script."
)
