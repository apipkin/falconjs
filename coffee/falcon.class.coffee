class Falcon.Class
	#--------------------------------------------------------
	# Attribute: Falcon.Class#observables
	#	This is a list of the default observables and values for
	#	this view on each instantiation. If the value is a function
	#	a computed is created. If the value is an object with the keys
	#	'read' and/or 'write' a computed is created with those object
	#	keys as the defining variables. All computeds are created with
	#	this view's instance bound to its callback methods
	#--------------------------------------------------------
	observables: null

	#--------------------------------------------------------
	# Method: Falcon.Class.extend
	#	Used to extend (as in, inherit) from one class to another
	#
	# Arguments:
	#	**parent** _(Object)_ - The parent to extend from
	#	**definition** _(Object)_ - The child's class definition
	#
	# Returns:
	#	_(Objec)t_ - The extended class
	#--------------------------------------------------------
	@extend = (instanceDef, staticDef) ->
		instanceDef ?= {}
		staticDef ?= {}

		parent = this
		child = null

		#Check if the instance defintion has a constrctor,
		#if not, generate one that calls the parent constructor
		if Object::hasOwnProperty.call(instanceDef, "constructor")
			child = instanceDef.constructor
		else
			child = -> parent.apply(this, arguments)
		#END if

		#Setup the prototype chain
		ctor = ( -> this.constructor = child )
		ctor.prototype = parent.prototype
		child.prototype = new ctor

		#Add instance methods
		extend( child.prototype, instanceDef )

		#Add static methods
		extend( child, parent ) #First add any static attributes from the parent
		extend( child, staticDef ) #Now add any static method being defined

		#Store the parent's prototype for use later
		child.__super__ = parent.prototype

		return child
	#END Falcon.Class.extend

	#--------------------------------------------------------
	# Local event storage
	#--------------------------------------------------------
	__falcon_class__events__: null

	#--------------------------------------------------------
	# Method: Falcon.Class()
	#	The constructor method
	#--------------------------------------------------------
	constructor: ->
		@__falcon_class__events__ = {}

		#Setup the observables
		if isObject( @observables )
			for key, value of @observables
				if isFunction( value )
					@[key] = ko.computed
						'read': value
						'owner': @
					#END computed
				else if isObject( value ) and ('read' of value or 'write' of value)
					@[key] = ko.computed
						'read': value.read
						'write': value.write
						'owner': @
					#END computed
				else if isArray( value )
					@[key] = ko.observableArray( value )
				else
					@[key] = ko.observable( value )
				#END if
			#END for
		#END if
	#END constructor

	#--------------------------------------------------------
	# Method: Falcon.Model#on()
	#	Adds an event listener to a specific event
	#
	# Arguments:
	#	**event** _(string)_ - The event to listen tpo
	#	**action** _(function)_ - The callback function to attach to this event
	#	**context** _(mixed)_ - The context to apply to the callback. Defaults to this model
	#
	# Returns:
	#	_(Falcon.Model)_ - This instance
	#--------------------------------------------------------
	on: (event, action, context) ->
		return this unless isString(event) and isFunction(action)

		context ?= this
		event = trim(event).toLowerCase()

		return this if isEmpty(event)

		( @__falcon_class__events__[event] ?= [] ).push({action, context})

		return this
	#END on

	#--------------------------------------------------------
	# Method: Falcon.Model#off()
	#	Removes an event listener from an event
	#
	# Arguments:
	#	**event** _(string)_ - The event to remove from
	#	**action** _(function)_ - The event handler to remove
	#
	# Returns:
	#	_(Falcon.Model)_ - This instance
	#--------------------------------------------------------
	off: (event, action) ->
		return this unless isString(event)

		event = trim(event).toLowerCase()

		return this if isEmpty(event) or not @__falcon_class__events__[event]?

		if isFunction( action )
			@__falcon_class__events__[event] = ( evt for evt in @__falcon_class__events__[event] when evt.action isnt action )
			@__falcon_class__events__[event] = null if @__falcon_class__events__[event].length <= 0
		else
			@__falcon_class__events__[event] = null
		#END if

		return this
	#END off

	#--------------------------------------------------------
	# Method: Falcon.Model#has
	#	Method used to see if this model has a specific event attached
	#
	# Arguments:
	#	**event** _(string)_ - The event to look at
	#	**action** _(function)_ - The event handler to look for
	#
	# Returns:
	#	_(boolean)_ - Did we find the event?
	#--------------------------------------------------------
	has: (event, action) ->
		return false unless isString(event)

		event = trim(event).toLowerCase()

		return false if isEmpty(event) or not @__falcon_class__events__[event]?
		return true if @__falcon_class__events__[event]? and not isFunction( action )

		return true for evt in @__falcon_class__events__[event] when evt.action is action

		return false
	#END has
		
	#--------------------------------------------------------
	# Method: Falcon.Model#trigger()
	#	Used to trigger a specific event
	#
	# Arguments:
	#	**event** _(string)_ - The event to trigger
	#	**args...** _(arguments)_ - Additional arguments to pass into the
	#								event listeners
	#
	# Returns:
	#	_(Falcon.Model)_ - This instance
	#--------------------------------------------------------
	trigger: (event, args...) ->
		return this unless isString(event)
		event = trim(event).toLowerCase()

		return this if isEmpty(event) or not @__falcon_class__events__[event]?

		evt.action.apply(evt.context, args) for evt in @__falcon_class__events__[event]

		return this
	#END trigger
#END Falcon.Class