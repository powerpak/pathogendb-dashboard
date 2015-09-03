class Dashing.Graph extends Dashing.Widget

  @accessor 'current', ->
    return @get('displayedValue') if @get('displayedValue')?
    points = @get('series') && @get('series')[0]
    if points
      points[points.length - 1].y

  ready: ->
    container = $(@node).parent()
    # Gross hacks. Let's fix this.
    width = (Dashing.widget_base_dimensions[0] * container.data("sizex")) + Dashing.widget_margins[0] * 2 * (container.data("sizex") - 1)
    height = (Dashing.widget_base_dimensions[1] * container.data("sizey"))
    @graph = new Rickshaw.Graph(
      element: $(@node).children('.rickshaw_plot_area').get(0)
      width: width - 40
      height: height
      renderer: "area" #@get("graphtype")
      stroke: true
      interpolation: 'step-after'
      stack: false
      padding: 
        top: 0.1
      series: [
        {
          color: "rgba(255,255,255,0.5)"
          stroke: "rgba(255,255,255,0.8)"
          data: [{x: Math.floor(Date.now() / 1000), y: 0}]
        },
        {
          color: "rgba(255,255,255,1.0)"
          stroke: "rgba(255,255,255,1.0)"
          data: [{x: Math.floor(Date.now() / 1000), y: 0}]
        }
      ]
    )
    
    if @get('series')
      @graph.series[i].data = data for data, i in @get('series')
    
    x_axis = new Rickshaw.Graph.Axis.Time(graph: @graph)
    y_axis = new Rickshaw.Graph.Axis.Y({
      graph: @graph
      tickFormat: Rickshaw.Fixtures.Number.formatKMBT
      orientation: 'left'
      element: $(@node).children('.rickshaw_y_axis').get(0)
    })
    @graph.render()

  onData: (data) ->
    console.log(data.series)
    if @graph && data.series
      @graph.series[i].data = data for data, i in data.series
      @graph.render()
