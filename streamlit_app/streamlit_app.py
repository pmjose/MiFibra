import streamlit as st

try:
    from snowflake.snowpark.context import get_active_session
    session = get_active_session()
except:
    from snowflake.snowpark import Session
    session = Session.builder.config('connection_name', 'default').create()

MIFIBRA_CSS = """
<style>
@import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');

:root {
    --mifibra-primary: #00A0E3;
    --mifibra-secondary: #003366;
    --mifibra-accent: #FF6B00;
    --mifibra-dark: #1a1a2e;
    --mifibra-light: #f8f9fa;
    --mifibra-gradient: linear-gradient(135deg, #00A0E3 0%, #003366 100%);
}

html, body, [class*="st-"] {
    font-family: 'Poppins', sans-serif;
}

.stApp {
    background: linear-gradient(180deg, #f8f9fa 0%, #e9ecef 100%);
}

[data-testid="stSidebar"] {
    background: linear-gradient(180deg, #003366 0%, #001a33 100%);
}

[data-testid="stSidebar"] [data-testid="stMarkdownContainer"] p,
[data-testid="stSidebar"] [data-testid="stMarkdownContainer"] h1,
[data-testid="stSidebar"] [data-testid="stMarkdownContainer"] h2,
[data-testid="stSidebar"] [data-testid="stMarkdownContainer"] h3,
[data-testid="stSidebar"] label {
    color: white !important;
}

[data-testid="stSidebar"] .stRadio label {
    color: white !important;
}

[data-testid="stSidebar"] .stRadio div[role="radiogroup"] label {
    color: white !important;
    background: rgba(255,255,255,0.1);
    border-radius: 8px;
    padding: 10px 15px;
    margin: 5px 0;
    transition: all 0.3s ease;
}

[data-testid="stSidebar"] .stRadio div[role="radiogroup"] label:hover {
    background: rgba(0,160,227,0.3);
}

.header-container {
    background: var(--mifibra-gradient);
    padding: 20px 30px;
    border-radius: 15px;
    margin-bottom: 30px;
    box-shadow: 0 10px 30px rgba(0,51,102,0.3);
}

.header-title {
    color: white;
    font-size: 2.5rem;
    font-weight: 700;
    margin: 0;
    text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
}

.header-subtitle {
    color: rgba(255,255,255,0.9);
    font-size: 1.1rem;
    font-weight: 300;
    margin-top: 5px;
}

.logo-container {
    text-align: center;
    padding: 20px 10px;
    margin-bottom: 20px;
    border-bottom: 1px solid rgba(255,255,255,0.2);
}

.logo-container img {
    max-width: 120px;
    border-radius: 15px;
}

.brand-name {
    color: white;
    font-size: 1.5rem;
    font-weight: 700;
    margin-top: 10px;
    letter-spacing: 1px;
}

.brand-tagline {
    color: rgba(255,255,255,0.7);
    font-size: 0.8rem;
    font-weight: 300;
}

.menu-header {
    color: var(--mifibra-primary) !important;
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 2px;
    margin: 20px 0 10px 0;
    padding-left: 5px;
}

.dashboard-card {
    background: white;
    border-radius: 15px;
    padding: 25px;
    box-shadow: 0 5px 20px rgba(0,0,0,0.08);
    border-left: 4px solid var(--mifibra-primary);
    margin-bottom: 20px;
    transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.dashboard-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 15px 40px rgba(0,0,0,0.12);
}

.metric-value {
    font-size: 2.5rem;
    font-weight: 700;
    color: var(--mifibra-secondary);
}

.metric-label {
    font-size: 0.9rem;
    color: #6c757d;
    text-transform: uppercase;
    letter-spacing: 1px;
}

.metric-delta-positive {
    color: #28a745;
    font-size: 0.85rem;
}

.metric-delta-negative {
    color: #dc3545;
    font-size: 0.85rem;
}

.empty-state {
    text-align: center;
    padding: 80px 40px;
    background: white;
    border-radius: 20px;
    box-shadow: 0 5px 20px rgba(0,0,0,0.08);
}

.empty-state-icon {
    font-size: 4rem;
    margin-bottom: 20px;
}

.empty-state-title {
    font-size: 1.5rem;
    font-weight: 600;
    color: var(--mifibra-secondary);
    margin-bottom: 10px;
}

.empty-state-text {
    color: #6c757d;
    font-size: 1rem;
}

.fiber-badge {
    display: inline-block;
    background: var(--mifibra-accent);
    color: white;
    padding: 5px 15px;
    border-radius: 20px;
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 1px;
}

.stButton > button {
    background: var(--mifibra-gradient);
    color: white;
    border: none;
    border-radius: 10px;
    padding: 10px 25px;
    font-weight: 600;
    transition: all 0.3s ease;
}

.stButton > button:hover {
    box-shadow: 0 5px 20px rgba(0,160,227,0.4);
    transform: translateY(-2px);
}

.footer {
    text-align: center;
    padding: 20px;
    color: #6c757d;
    font-size: 0.85rem;
    margin-top: 50px;
    border-top: 1px solid #dee2e6;
}
</style>
"""

st.markdown(MIFIBRA_CSS, unsafe_allow_html=True)

LOGO_URL = "https://play-lh.googleusercontent.com/fjNKM1iZWwPmP9AYMc3obowV0GqsaT6CYhXoieAUdDY1IE-TXsvLE9TL6_gm_suPS6Y"

with st.sidebar:
    st.markdown(f"""
        <div class="logo-container">
            <img src="{LOGO_URL}" alt="MiFibra Logo">
            <div class="brand-name">MiFibra</div>
            <div class="brand-tagline">Fibra 100% Pura</div>
        </div>
    """, unsafe_allow_html=True)
    
    st.markdown('<p class="menu-header">Navigation</p>', unsafe_allow_html=True)
    
    menu_options = [
        "Executive Overview",
        "Subscribers",
        "Revenue Analytics",
        "Network Status",
        "Marketing",
        "HR & Workforce",
        "Settings"
    ]
    
    selected_menu = st.radio(
        label="Menu",
        options=menu_options,
        label_visibility="collapsed"
    )
    
    st.markdown("---")
    st.markdown("""
        <div style="text-align: center; padding: 10px;">
            <span class="fiber-badge">XGS-PON</span>
        </div>
    """, unsafe_allow_html=True)
    
    st.markdown("""
        <div style="color: rgba(255,255,255,0.5); font-size: 0.7rem; text-align: center; margin-top: 20px;">
            v1.0.0 | Peru
        </div>
    """, unsafe_allow_html=True)

st.markdown("""
    <div class="header-container">
        <h1 class="header-title">Executive Dashboard</h1>
        <p class="header-subtitle">Real-time insights for MiFibra Peru leadership team</p>
    </div>
""", unsafe_allow_html=True)

if selected_menu == "Executive Overview":
    st.markdown("""
        <div class="empty-state">
            <div class="empty-state-icon">📊</div>
            <div class="empty-state-title">Executive Overview Dashboard</div>
            <div class="empty-state-text">
                Dashboard components will be added here.<br>
                Connect to Snowflake data sources to populate metrics.
            </div>
        </div>
    """, unsafe_allow_html=True)
    
elif selected_menu == "Subscribers":
    st.markdown("""
        <div class="empty-state">
            <div class="empty-state-icon">👥</div>
            <div class="empty-state-title">Subscriber Analytics</div>
            <div class="empty-state-text">Coming soon</div>
        </div>
    """, unsafe_allow_html=True)

elif selected_menu == "Revenue Analytics":
    st.markdown("""
        <div class="empty-state">
            <div class="empty-state-icon">💰</div>
            <div class="empty-state-title">Revenue Analytics</div>
            <div class="empty-state-text">Coming soon</div>
        </div>
    """, unsafe_allow_html=True)

elif selected_menu == "Network Status":
    st.markdown("""
        <div class="empty-state">
            <div class="empty-state-icon">🌐</div>
            <div class="empty-state-title">Network Status</div>
            <div class="empty-state-text">Coming soon</div>
        </div>
    """, unsafe_allow_html=True)

elif selected_menu == "Marketing":
    st.markdown("""
        <div class="empty-state">
            <div class="empty-state-icon">📢</div>
            <div class="empty-state-title">Marketing Analytics</div>
            <div class="empty-state-text">Coming soon</div>
        </div>
    """, unsafe_allow_html=True)

elif selected_menu == "HR & Workforce":
    st.markdown("""
        <div class="empty-state">
            <div class="empty-state-icon">👔</div>
            <div class="empty-state-title">HR & Workforce</div>
            <div class="empty-state-text">Coming soon</div>
        </div>
    """, unsafe_allow_html=True)

elif selected_menu == "Settings":
    st.markdown("""
        <div class="empty-state">
            <div class="empty-state-icon">⚙️</div>
            <div class="empty-state-title">Settings</div>
            <div class="empty-state-text">Coming soon</div>
        </div>
    """, unsafe_allow_html=True)

st.markdown("""
    <div class="footer">
        MiFibra Peru © 2026 | Powered by Snowflake
    </div>
""", unsafe_allow_html=True)
