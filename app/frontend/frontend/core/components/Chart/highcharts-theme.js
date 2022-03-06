export default {
  // special colors for some of the
  background2: '#505053',

  chart: {
    backgroundColor: 'transparent',
    plotBorderColor: '#606063',
    style: {
      fontSize: '11px',
    },
  },

  colors: [
    '#428bca',
    '#90ee7e',
    '#f45b5b',
    '#7798BF',
    '#aaeeee',
    '#ff0066',
    '#eeaaee',
    '#55BF3B',
    '#DF5353',
    '#7798BF',
    '#aaeeee',
  ],

  contrastTextColor: '#F0F0F3',

  credits: {
    enabled: false,
  },

  dataLabelsColor: '#B0B0B3',

  drilldown: {
    activeAxisLabelStyle: {
      color: '#F0F0F3',
    },
    activeDataLabelStyle: {
      color: '#F0F0F3',
    },
  },

  labels: {
    style: {
      color: '#707073',
    },
  },

  legend: {
    borderWidth: 0,
    itemHiddenStyle: {
      color: '#606063',
    },
    itemHoverStyle: {
      color: '#FFF',
    },
    itemMarginBottom: 3,
    itemStyle: {
      color: '#E0E0E3',
    },
  },

  legendBackgroundColor: 'rgba(0, 0, 0, 0.5)',

  maskColor: 'rgba(255,255,255,0.3)',

  navigation: {
    buttonOptions: {
      symbolStroke: '#DDDDDD',
      theme: {
        fill: '#505053',
      },
    },
  },

  navigator: {
    handles: {
      backgroundColor: '#666',
      borderColor: '#AAA',
    },
    maskFill: 'rgba(255,255,255,0.1)',
    outlineColor: '#CCC',
    series: {
      color: '#7798BF',
      lineColor: '#A6C7ED',
    },
    xAxis: {
      gridLineColor: '#505053',
    },
  },

  plotOptions: {
    area: {
      fillColor: 'rgba(66, 139, 202, 0.3)',
    },
    bar: {
      borderColor: '#333',
    },
    boxplot: {
      fillColor: '#505053',
    },
    candlestick: {
      lineColor: 'white',
    },
    column: {
      borderColor: '#333',
    },
    errorbar: {
      color: 'white',
    },
    pie: {
      allowPointSelect: true,
      borderColor: '#333',
      cursor: 'pointer',
      dataLabels: {
        enabled: false,
      },
      innerSize: '50%',
      showInLegend: true,
    },
    series: {
      dataLabels: {
        color: '#B0B0B3',
      },
      marker: {
        lineColor: '#333',
      },
    },
  },

  // scroll charts
  rangeSelector: {
    buttonTheme: {
      fill: '#505053',
      states: {
        hover: {
          fill: '#707073',
          stroke: '#000000',
          style: {
            color: 'white',
          },
        },
        select: {
          fill: '#000003',
          stroke: '#000000',
          style: {
            color: 'white',
          },
        },
      },
      stroke: '#000000',
      style: {
        color: '#CCC',
      },
    },
    inputBoxBorderColor: '#505053',
    inputStyle: {
      backgroundColor: '#333',
      color: 'silver',
    },
    labelStyle: {
      color: 'silver',
    },
  },

  scrollbar: {
    barBackgroundColor: '#808083',
    barBorderColor: '#808083',
    buttonArrowColor: '#CCC',
    buttonBackgroundColor: '#606063',
    buttonBorderColor: '#606063',
    rifleColor: '#FFF',
    trackBackgroundColor: '#404043',
    trackBorderColor: '#404043',
  },

  subtitle: {
    style: {
      color: '#E0E0E3',
      textTransform: 'uppercase',
    },
  },

  textColor: '#C0C0C0',

  title: {
    style: {
      color: '#E0E0E3',
      fontSize: '20px',
      textTransform: 'uppercase',
    },
    text: null,
  },

  tooltip: {
    backgroundColor: 'rgba(0, 0, 0, 0.85)',
    style: {
      color: '#F0F0F0',
      fontSize: '12px',
    },
  },
  xAxis: {
    labels: {
      style: {
        color: '#E0E0E3',
        fontSize: '12px',
      },
    },
    lineColor: '#707073',
    minorGridLineColor: '#505053',
    tickColor: '#707073',
    tickWidth: 1,
    title: {
      style: {
        color: '#A0A0A3',
      },
      text: null,
    },
  },
  yAxis: {
    gridLineColor: '#707073',
    gridLineWidth: 1,
    labels: {
      style: {
        color: '#E0E0E3',
        fontSize: '12px',
      },
    },
    lineColor: '#707073',
    minorGridLineColor: '#505053',
    tickColor: '#707073',
    tickWidth: 1,
    title: {
      style: {
        color: '#A0A0A3',
      },
      text: null,
    },
  },
}
