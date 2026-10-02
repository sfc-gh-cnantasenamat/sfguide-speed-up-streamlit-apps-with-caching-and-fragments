# Speed Up Streamlit Apps with Caching and Fragments

Companion repo for the Snowflake guide [Speed Up Streamlit Apps with Caching and Fragments](https://www.snowflake.com/en/developers/guides/speed-up-streamlit-apps-with-caching-and-fragments/).

A Streamlit app is easy to build until users start clicking filters. Every click reruns the whole script from top to bottom, and every data load runs again, even when nothing about the data changed. In this demo, the table and the chart each load the data, so the uncached app reads it twice on every click.

Two small changes fix this. `@st.cache_data` loads the data once and reuses it, and `@st.fragment` limits a filter click to rerunning just the filter section. In testing, reruns dropped from ~0.5s to ~0.02s.

![Before and after: the same app without and with @st.cache_data and @st.fragment](assets/before-after-caching.png)

## What's in this repo

| Path | Contents |
|---|---|
| `before/streamlit_app.py` | A first-draft dashboard: no caching, no fragment |
| `after/streamlit_app.py` | The same file with `@st.cache_data` on the three data loads and `@st.fragment` on the filter section |
| `data/user_events.csv` | 200k synthetic user events (about 5% have no region) |

The two apps differ only by the decorators, so this shows every change:

```bash
diff before/streamlit_app.py after/streamlit_app.py
```

## Run locally

```bash
git clone https://github.com/Snowflake-Labs/sfguide-speed-up-streamlit-apps-with-caching-and-fragments.git
cd sfguide-speed-up-streamlit-apps-with-caching-and-fragments
pip install -r after/requirements.txt
streamlit run before/streamlit_app.py --server.port 8601
streamlit run after/streamlit_app.py --server.port 8602
```

Each app has a **Reset cache** button and a **Run timing** panel. Click **Reset cache**, change the Region filter a few times, and compare the two apps.

## Load from Snowflake

The apps pick their data source based on where they run. Locally or on Streamlit Community Cloud, they read the bundled CSV, so no credentials are needed. In Streamlit in Snowflake, `load_events()` queries a `USER_EVENTS_DEMO` table through the app's Snowpark session. Load `data/user_events.csv` into that table before deploying. Deploy on the container runtime with an external access integration that allows PyPI, so it can install the packages in `pyproject.toml`. `load_filtered()` and `load_mau()` don't change.

## License

Apache 2.0. See [LICENSE](LICENSE).
