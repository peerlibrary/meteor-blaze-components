class BlazeComponentDebug extends BaseComponentDebug
  @startComponent: (component) ->
    super

    console.log component.data()

  @startMarkedComponent: (component) ->
    super

    console.log component.data()

  @dumpComponentSubtree: (rootComponentOrElement) ->
    if 'nodeType' of rootComponentOrElement and rootComponentOrElement.nodeType is Node.ELEMENT_NODE
      rootComponentOrElement = BlazeComponent.getComponentForElement rootComponentOrElement

    super

  @dumpComponentTree: (rootComponentOrElement) ->
    if 'nodeType' of rootComponentOrElement and rootComponentOrElement.nodeType is Node.ELEMENT_NODE
      rootComponentOrElement = BlazeComponent.getComponentForElement rootComponentOrElement

    super

  @dumpAllComponents: ->
    allRootComponents = []

    $('*').each (i, element) =>
      component = BlazeComponent.getComponentForElement element
      return unless component
      rootComponent = @componentRoot component
      allRootComponents.push rootComponent unless rootComponent in allRootComponents

    for rootComponent in allRootComponents
      @dumpComponentSubtree rootComponent

    return
