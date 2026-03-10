# E-Commerce Retail Analytics & Customer Segmentation

## Overview
End-to-end data science project analyzing 541,909 UK retail 
transactions to uncover revenue trends and segment customers 
using RFM Analysis and K-Means Clustering.

## Tools Used
- **MySQL** — Data importing, cleaning & analysis
- **Python** — RFM Analysis & K-Means Clustering
- **Libraries** — Pandas, Matplotlib, Seaborn, Scikit-learn

## Key Findings
- 102% revenue growth over 12 months
- 27% dirty data removed through advanced cleaning
- International customers had 5x higher order values than UK customers
- 4 customer segments identified via K-Means Clustering
- 78% of customers were At Risk or Lost
- Top 5% Champion customers generated 20x more revenue

## Project Structure
```
├── retail_analysis.sql          # All SQL queries
├── customer_segmentation.ipynb  # Python notebook
├── rfm_data.csv                 # Cleaned RFM data
└── customer_segmentation.png    # Visualization
```

## SQL Techniques Used
- Window Functions (LAG, NTILE, RANK)
- Common Table Expressions (CTEs)
- Aggregate Functions
- Data Cleaning & Transformation
- LOAD DATA INFILE

## Python Techniques Used
- Exploratory Data Analysis
- Feature Scaling (StandardScaler)
- Elbow Method & Silhouette Score
- K-Means Clustering
- Data Visualization

## Customer Segments Found
| Segment | Customers | Avg Spending |
| Champions | 5.1% | £11,000+ |
| Loyal Customers | 16.3% | £4,300 |
|  At Risk | 59.2% | £1,200 |
| Lost Customers | 19.4% | £550 |

## How to Run
1. Download `Online Retail` dataset from Kaggle
2. Import into MySQL using `LOAD DATA INFILE`
3. Run `retail_analysis.sql` for complete analysis
4. Export `rfm_data.csv` from MySQL
5. Run `customer_segmentation.ipynb` in Jupyter Notebook

## Dataset
- **Source:** UCI Machine Learning Repository / Kaggle
- **Records:** 541,909 transactions
- **Period:** December 2010 — December 2011
- **Region:** Primarily UK based retailer
