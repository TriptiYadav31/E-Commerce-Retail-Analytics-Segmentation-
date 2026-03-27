import streamlit as st
import pandas as pd
import plotly.express as px
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans

# ================================================
# PAGE CONFIGURATION
# ================================================
st.set_page_config(
    page_title="E-Commerce Retail Analytics",
    page_icon="🛒",
    layout="wide"
)

# ================================================
# TITLE
# ================================================
st.title("🛒 E-Commerce Retail Analytics & Customer Segmentation")
st.markdown("**Dataset:** Online Retail | **Period:** Dec 2010 - Dec 2011 | **Records:** 541,909 transactions")
st.markdown("---")

# ================================================
# LOAD DATA
# ================================================
@st.cache_data
def load_data():
    monthly = pd.read_csv('Monthly_Revenue.csv')
    products = pd.read_csv('Products_Summary.csv')
    countries = pd.read_csv('Country_Summary.csv')
    customers = pd.read_csv('Customer_Summary.csv')
    rfm = pd.read_csv('rfm_data.csv')
    return monthly, products, countries, customers, rfm

monthly, products, countries, customers, rfm = load_data()

# ================================================
# SIDEBAR
# ================================================
st.sidebar.title("📊 Navigation")
page = st.sidebar.radio("Go to", [
    "📈 Revenue Trends",
    "🛍️ Product Analysis",
    "🌍 Country Analysis",
    "👥 Customer Analysis",
    "🎯 RFM & Clustering"
])

# ================================================
# PAGE 1: REVENUE TRENDS
# ================================================
if page == "📈 Revenue Trends":
    st.header("📈 Revenue Trends")

    col1, col2, col3, col4 = st.columns(4)
    col1.metric("Total Revenue", f"£{monthly['Monthly_Revenue'].sum():,.0f}")
    col2.metric("Total Orders", f"{monthly['Total_Orders'].sum():,.0f}")
    col3.metric("Peak Month", monthly.loc[monthly['Monthly_Revenue'].idxmax(), 'Month'])
    col4.metric("Revenue Growth", "102%")

    st.markdown("---")

    fig = px.line(monthly, x='Month', y='Monthly_Revenue',
                  title='Monthly Revenue Trend',
                  markers=True,
                  color_discrete_sequence=['#2ecc71'])
    fig.update_layout(xaxis_title='Month', yaxis_title='Revenue (£)')
    st.plotly_chart(fig, use_container_width=True)

    col1, col2 = st.columns(2)
    with col1:
        fig2 = px.bar(monthly, x='Month', y='Total_Orders',
                      title='Monthly Orders',
                      color_discrete_sequence=['#3498db'])
        st.plotly_chart(fig2, use_container_width=True)

    with col2:
        fig3 = px.bar(monthly, x='Month', y='Unique_Customers',
                      title='Monthly Unique Customers',
                      color_discrete_sequence=['#e74c3c'])
        st.plotly_chart(fig3, use_container_width=True)

# ================================================
# PAGE 2: PRODUCT ANALYSIS
# ================================================
elif page == "🛍️ Product Analysis":
    st.header("🛍️ Product Analysis")

    tab1, tab2 = st.tabs(["By Revenue", "By Quantity"])

    with tab1:
        top_revenue = products.nlargest(10, 'Total_Revenue')
        fig = px.bar(top_revenue,
                     x='Total_Revenue',
                     y='Description',
                     orientation='h',
                     title='Top 10 Products by Revenue',
                     color='Total_Revenue',
                     color_continuous_scale='Greens')
        fig.update_layout(yaxis={'categoryorder': 'total ascending'})
        st.plotly_chart(fig, use_container_width=True)
        st.dataframe(top_revenue)

    with tab2:
        top_qty = products.nlargest(10, 'Total_Quantity_Sold')
        fig2 = px.bar(top_qty,
                      x='Total_Quantity_Sold',
                      y='Description',
                      orientation='h',
                      title='Top 10 Products by Quantity',
                      color='Total_Quantity_Sold',
                      color_continuous_scale='Blues')
        fig2.update_layout(yaxis={'categoryorder': 'total ascending'})
        st.plotly_chart(fig2, use_container_width=True)
        st.dataframe(top_qty)

# ================================================
# PAGE 3: COUNTRY ANALYSIS
# ================================================
elif page == "🌍 Country Analysis":
    st.header("🌍 Country Analysis")

    col1, col2 = st.columns(2)

    with col1:
        fig = px.bar(countries.head(10),
                     x='Country',
                     y='Total_Revenue',
                     title='Top 10 Countries by Revenue',
                     color='Total_Revenue',
                     color_continuous_scale='Oranges')
        st.plotly_chart(fig, use_container_width=True)

    with col2:
        fig2 = px.pie(countries.head(10),
                      values='Total_Revenue',
                      names='Country',
                      title='Revenue Share by Country')
        st.plotly_chart(fig2, use_container_width=True)

    fig3 = px.choropleth(countries,
                         locations='Country',
                         locationmode='country names',
                         color='Total_Revenue',
                         title='Revenue by Country - World Map',
                         color_continuous_scale='Turbo')
    st.plotly_chart(fig3, use_container_width=True)
    st.dataframe(countries)

# ================================================
# PAGE 4: CUSTOMER ANALYSIS
# ================================================
elif page == "👥 Customer Analysis":
    st.header("👥 Customer Analysis")

    col1, col2, col3 = st.columns(3)
    col1.metric("Total Customers", f"{len(customers):,.0f}")
    col2.metric("Avg Order Value", f"£{customers['Avg_Order_Value'].mean():,.2f}")
    col3.metric("Top Customer Spent", f"£{customers['Total_Spent'].max():,.2f}")

    st.markdown("---")

    col1, col2 = st.columns(2)

    with col1:
        top_customers = customers.nlargest(10, 'Total_Spent')
        fig = px.bar(top_customers,
                     x='Customer_ID',
                     y='Total_Spent',
                     title='Top 10 Customers by Spending',
                     color='Total_Spent',
                     color_continuous_scale='Greens')
        st.plotly_chart(fig, use_container_width=True)

    with col2:
        fig2 = px.scatter(customers,
                          x='Total_Orders',
                          y='Total_Spent',
                          title='Orders vs Spending',
                          color='Country',
                          hover_data=['Customer_ID'])
        st.plotly_chart(fig2, use_container_width=True)

    st.dataframe(customers.nlargest(20, 'Total_Spent'))

# ================================================
# PAGE 5: RFM & CLUSTERING
# ================================================
elif page == "🎯 RFM & Clustering":
    st.header("🎯 RFM Analysis & Customer Segmentation")

    scaler = StandardScaler()
    rfm_scaled = scaler.fit_transform(rfm[['Recency', 'Frequency', 'Monetary']])
    kmeans = KMeans(n_clusters=4, random_state=42)
    rfm['Cluster'] = kmeans.fit_predict(rfm_scaled)

    cluster_labels = {0: 'Loyal Customers', 1: 'Lost Customers',
                      2: 'At Risk', 3: 'Champions'}
    rfm['Segment'] = rfm['Cluster'].map(cluster_labels)

    col1, col2, col3, col4 = st.columns(4)
    for i, (segment, icon) in enumerate(zip(
        ['Champions', 'Loyal Customers', 'At Risk', 'Lost Customers'],
        ['🏆', '💚', '⚠️', '😴']
    )):
        count = len(rfm[rfm['Segment'] == segment])
        [col1, col2, col3, col4][i].metric(f"{icon} {segment}", f"{count} customers")

    st.markdown("---")

    col1, col2 = st.columns(2)

    with col1:
        segment_counts = rfm['Segment'].value_counts().reset_index()
        segment_counts.columns = ['Segment', 'Count']
        fig = px.pie(segment_counts,
                     values='Count',
                     names='Segment',
                     title='Customer Segments Distribution',
                     color_discrete_sequence=['#2ecc71', '#e74c3c', '#f39c12', '#3498db'])
        st.plotly_chart(fig, use_container_width=True)

    with col2:
        avg_spending = rfm.groupby('Segment')['Monetary'].mean().reset_index()
        fig2 = px.bar(avg_spending,
                      x='Segment',
                      y='Monetary',
                      title='Average Spending by Segment',
                      color='Segment',
                      color_discrete_sequence=['#2ecc71', '#e74c3c', '#f39c12', '#3498db'])
        st.plotly_chart(fig2, use_container_width=True)

    col1, col2 = st.columns(2)

    with col1:
        fig3 = px.scatter(rfm,
                          x='Recency',
                          y='Monetary',
                          color='Segment',
                          title='Recency vs Monetary',
                          color_discrete_sequence=['#2ecc71', '#e74c3c', '#f39c12', '#3498db'])
        st.plotly_chart(fig3, use_container_width=True)

    with col2:
        fig4 = px.scatter(rfm,
                          x='Frequency',
                          y='Monetary',
                          color='Segment',
                          title='Frequency vs Monetary',
                          color_discrete_sequence=['#2ecc71', '#e74c3c', '#f39c12', '#3498db'])
        st.plotly_chart(fig4, use_container_width=True)

    st.markdown("### 📊 Segment Summary")
    summary = rfm.groupby('Segment').agg(
        Total_Customers=('Customer_ID', 'count'),
        Avg_Recency=('Recency', 'mean'),
        Avg_Frequency=('Frequency', 'mean'),
        Avg_Monetary=('Monetary', 'mean')
    ).round(2).reset_index()
    st.dataframe(summary)

    st.markdown("### Clustering Visualization")
    st.image('customer_segmentation.png')
