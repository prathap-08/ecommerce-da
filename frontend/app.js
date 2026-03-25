const num = (v) => Number(v || 0);
const money = (v) => num(v).toLocaleString(undefined, { maximumFractionDigits: 2 });

async function getJson(path) {
  const res = await fetch(path);
  if (!res.ok) {
    throw new Error(`API ${path} failed: ${res.status}`);
  }
  return await res.json();
}

function renderKpis(k) {
  const cards = [
    ["Revenue", money(k.total_revenue)],
    ["Profit", money(k.total_profit)],
    ["Margin %", `${k.profit_margin_pct}%`],
    ["Orders", money(k.total_orders)],
    ["Customers", money(k.total_customers)],
    ["AOV", money(k.avg_order_value)],
  ];

  const root = document.getElementById("kpiCards");
  root.innerHTML = cards
    .map(([label, value]) => `<article class="kpi-card"><h3>${label}</h3><p>${value}</p></article>`)
    .join("");
}

function renderTable(id, rows, columns) {
  const table = document.getElementById(id);
  if (!rows || !rows.length) {
    table.innerHTML = "<tr><td>No data available</td></tr>";
    return;
  }

  const thead = `<thead><tr>${columns.map((c) => `<th>${c.label}</th>`).join("")}</tr></thead>`;
  const tbody = `<tbody>${rows
    .map(
      (r) =>
        `<tr>${columns
          .map((c) => {
            const val = r[c.key];
            return `<td>${c.format ? c.format(val) : val}</td>`;
          })
          .join("")}</tr>`
    )
    .join("")}</tbody>`;

  table.innerHTML = `${thead}${tbody}`;
}

async function init() {
  try {
    const [kpis, monthly, products, regions, rfm, forecast] = await Promise.all([
      getJson("/api/kpis"),
      getJson("/api/monthly-trend"),
      getJson("/api/top-products?limit=10"),
      getJson("/api/region-sales"),
      getJson("/api/rfm-summary"),
      getJson("/api/forecast"),
    ]);

    renderKpis(kpis);

    renderTable("monthlyTable", monthly, [
      { key: "order_date", label: "Month" },
      { key: "revenue", label: "Revenue", format: money },
      { key: "orders", label: "Orders", format: money },
      { key: "profit", label: "Profit", format: money },
      { key: "mom_growth_pct", label: "MoM %", format: (v) => (v === "" || v === null ? "NA" : `${Number(v).toFixed(2)}%`) },
    ]);

    renderTable("productsTable", products, [
      { key: "product_name", label: "Product" },
      { key: "category", label: "Category" },
      { key: "total_units", label: "Units", format: money },
      { key: "total_revenue", label: "Revenue", format: money },
      { key: "total_profit", label: "Profit", format: money },
    ]);

    renderTable("regionTable", regions, [
      { key: "region", label: "Region" },
      { key: "revenue", label: "Revenue", format: money },
      { key: "profit", label: "Profit", format: money },
      { key: "margin_pct", label: "Margin %", format: (v) => `${Number(v).toFixed(2)}%` },
    ]);

    renderTable("rfmTable", rfm, [
      { key: "rfm_segment", label: "Segment" },
      { key: "customers", label: "Customers", format: money },
      { key: "revenue", label: "Revenue", format: money },
      { key: "avg_recency_days", label: "Avg Recency", format: (v) => Number(v).toFixed(1) },
    ]);

    renderTable("forecastTable", forecast, [
      { key: "month", label: "Month" },
      { key: "forecast_revenue", label: "Forecast Revenue", format: money },
      { key: "forecast_index", label: "Index", format: (v) => Number(v).toFixed(3) },
    ]);
  } catch (err) {
    document.body.insertAdjacentHTML(
      "beforeend",
      `<div style="padding:12px 24px;color:#b42318;font-family:IBM Plex Mono,monospace;">${err.message}</div>`
    );
  }
}

init();
