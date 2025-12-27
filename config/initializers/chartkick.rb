# Zephyr Bootstrap Theme Colors
# Primary: #0ea8d9 (cyan-blue)
# Success: #3fb618 (green)
# Info: #9954bb (purple)
# Warning: #ff7518 (orange)
# Danger: #ff0039 (red)

Chartkick.options = {
  colors: [ "#0ea8d9", "#3fb618", "#ff7518", "#9954bb", "#ff0039" ],
  library: {
    responsive: true,
    maintainAspectRatio: false,
    interaction: {
      mode: 'index',
      intersect: false
    },
    plugins: {
      legend: {
        position: "bottom",
        labels: {
          padding: 15,
          font: {
            size: 12
          }
        }
      },
      tooltip: {
        enabled: true,
        mode: 'index',
        intersect: false
      }
    },
    scales: {
      x: {
        display: true,
        grid: {
          display: true,
          color: 'rgba(0, 0, 0, 0.05)'
        }
      },
      y: {
        display: true,
        grid: {
          display: true,
          color: 'rgba(0, 0, 0, 0.05)'
        }
      }
    }
  }
}
