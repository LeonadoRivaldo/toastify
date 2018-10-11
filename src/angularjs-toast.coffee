'use strict'

angular.module 'angularjsToast', ['ngSanitize', 'ngAnimate']
  .factory 'toast', ($rootScope, $http, $templateCache, $compile, $timeout) ->

    # template
    templateBase = 'angularjs-toast.html'

    html = '<div class="angularjs-toast" ng-class="$toastPlace ? \'position-fixed\' : \'position-relative\'">'+
    '  <ul class="toast-container" ng-class="[$position, $masterClass]">'+
    '    <li class="animate-repeat toast-item" ng-repeat="data in $toastMessages track by data.id" ng-click="$onclick($event, $index, data.data)">'+
    '      <div class="alert alert-dismissible" ng-class="::$toastClass">'+
    '        <span ng-bind-html="data.message"></span>'+
    '        <a href="javascript:void(0)" class="close" data-dismiss="alert" aria-label="{{$closeTitle}}" title="{{$closeTitle}}" ng-click="$close($index)" ng-if="$dismissible">×</a>'+
    '      </div>'+
    '    </li>'+
    '  </ul>'+
    '</div>'

    # put html into template cache
    $templateCache.put(templateBase, html)

    # default params
    container = document.querySelector('body')
    duration = 5000
    dismissible = true
    emptyMessage = "Hi there!"
    maxToast = 6
    position = 'right'
    toastClass = 'alert-success'

    # scope defaults
    scope = $rootScope.$new()
    scope.$toastMessages = []

    # toast function
    toast = (args) ->

      #function to manualy update scope;
      _scopeUpdate = ->
        setTimeout ->
          scope.$apply()
        , 10


      # user parameters
      args.duration = if args.duration then args.duration else duration
      args.maxToast = if args.maxToast then args.maxToast else maxToast
      #new option to the user be able to dont remove.
      args.removeOnTimeOut = if typeof args.removeOnTimeOut isnt 'undefined' then args.removeOnTimeOut else true
      args.insertFromTop = if typeof args.insertFromTop isnt 'undefined' then args.insertFromTop else true
      args.removeFromTop = if typeof args.removeFromTop isnt 'undefined' then args.removeFromTop else false
      args.container = if args.container then document.querySelector(args.container) else container
      args.data = if args.data then args.data else null

      # values that bind to HTML
      scope.$position = if args.position then args.position else position
      scope.$toastPlace = if args.container is container then true else false
      scope.$masterClass = if args.masterClass then args.masterClass else ''
      scope.$toastClass = if args.className then args.className else toastClass
      scope.$dismissible = if args.dismissible then args.dismissible else dismissible
      scope.$message = if args.message then args.message else emptyMessage
      scope.$closeTitle = if args.closeTitle then args.closeTitle else 'close'

      #user pass a onClickFn parameter it as a callback function to the toast
      scope.$onclick = ($event, $index, data) ->
        if args.onClickFn
          scope.$close($index)
          args.onClickFn($event, data)
          _scopeUpdate()
        return




      # check if templates are present in the body
      # append to body
      htmlTemplate = angular.element(document.getElementsByClassName 'angularjs-toast')

      if not htmlTemplate[0]
        # if the element is not appened to html
        # get default template from ->templateBase
        # append to ->args.container
        $http.get templateBase, {cache: $templateCache}
          .then (response) ->

            # compile the element
            # append default template to the ->templateBase
            templateElement = $compile(response.data)(scope)
            angular.element(args.container).append templateElement
            return

      # remove element besed on time interval ->args.duration
      timeout = (element) ->
        $timeout ->
          index = scope.$toastMessages.indexOf(element)
          if index isnt -1
            scope.$toastMessages.splice(index, 1)
            return
        , args.duration
        return

      # append inputs to json variable
      # this will be pushed to the ->scope.$toastMessages array
      json =
        message: args.message
        data: args.data
        id: (new Date().getTime() * Math.floor(Math.random() * 9999) + 1).toString(16) #set random ids it never collide and dont git ngdupes problem

      # push elements to array
      pushToArray = ->
        if args.insertFromTop then scope.$toastMessages.unshift(json) else scope.$toastMessages.push(json)
        #scope update bug correction
        _scopeUpdate()
        if args.removeOnTimeOut then timeout(json)
        return

      # remove last/ first element from ->scope.$toastMessages when the maxlength is reached
      # default maxlength is 6
      if scope.$toastMessages.length is args.maxToast
        if args.removeFromTop then scope.$toastMessages.shift() else scope.$toastMessages.pop()
        pushToArray()
      else
        pushToArray()

      # close selected element
      # remove ->$index element from ->scope.toastMessages
      scope.$close = (index) ->
        scope.$toastMessages.splice(index, 1)
        return
      return
