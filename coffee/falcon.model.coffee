#--------------------------------------------------------
# Class: Falcon.Model
#	Represents a model
#--------------------------------------------------------
class Falcon.Model extends Falcon.Class

	#--------------------------------------------------------
	# Method: Falcon.Model.extend()
	#	static method used to replicate inhertiance in
	#	javascript applications.  Used to create a new
	#	model that inherits from the base Falcon.Model
	#
	# Arguments:
	#	**properties** _(Object)_ -  The new class definition
	#
	# Returns:
	#	_(Object)_ - The new class definition
	#--------------------------------------------------------
	@extend = (properties) -> Falcon.Class.extend(Falcon.Model, properties)

	#--------------------------------------------------------
	# Member: Falcon.Model#id
	#	This is the serve's id of this model.  This value will be converted
	#	to an observable (keeping the same value) once this model is 
	#	instantiated.
	#--------------------------------------------------------
	id: null

	#--------------------------------------------------------
	# Member: Falcon.Model#url
	#	This is the top level url for the model.
	#--------------------------------------------------------
	url: null

	#--------------------------------------------------------
	# Member: Falcon.Model#parent
	#	This represents the 'parent' object that holds this
	#	model.  Generally this is used for determining the URL
	#	structure of rest objects in the makeURL() routine.
	#	This should also be a Model.
	#
	# Type: Falcon.Model
	#--------------------------------------------------------
	parent: null

	#--------------------------------------------------------
	# Member: Falcon.Model#fields
	# 	The fields to transfer to/from the server
	# 	Takes 2 forms
	#
	# Form 1: Array
	#	A list of array to directly map (1-to-1) model 
	#	attributes to server attributes
	#
	# Form 2: Object
	# 	A object of mapped fields
	#	The object's keys are the server attributes
	#	The object's values are the model attributes
	#
	# Type: Array, Object
	#--------------------------------------------------------
	fields: {}

	#--------------------------------------------------------
	# Method: Falcon.Model()
	#	The constructor for a model
	#
	# Arguments:
	#	**data** _(object)_ - The initial data to load in
	#	**parent** _(mixed)_ - The parent object of this one
	#--------------------------------------------------------
	constructor: (data, parent) ->
		super()
		
		data = ko.utils.unwrapObservable( data )
		parent = ko.utils.unwrapObservable( parent )

		[parent, data] = [data, parent] if parent? and not Falcon.isModel( parent ) and Falcon.isModel( data )
		[parent, data] = [data, parent] if not parent? and Falcon.isModel( data )

		data = data.unwrap() if Falcon.isModel(data)

		@parent = parent
		@initialize(data)
		@fill(data) unless isEmpty( data )

		#Lastly make sure that any of the fields that should exist, do
		if isArray( @fields )
			this[field] = null for field in @fields when isString(field) and not field of this
		else if isObject( @fields )
			this[model_field] = null for field, model_field of @fields when isString(field) and not field of this
		#END if
	#END constructor

	#--------------------------------------------------------
	# Method: Falcon.Model#initialize()
	#	The psuedo-constructor of the model.  Useful for ensuring that
	#	the base constructor is called (in the correct spot) without 
	#	having to explicitly call the native Model constructor
	#
	# Arguments:
	#	**data** _(object)_ - The initial data to load in
	#--------------------------------------------------------
	initialize: (data) ->
	#END initialize

	#--------------------------------------------------------
	# Method: Falcon.Model#get()
	#	Gets am observable-less value for a specific key
	#
	# Arguments:
	#	**key** _(string)_ - The key to look up
	#
	# Returns:
	#	_(mixed)_ - The unwrapped value at the specific key
	#--------------------------------------------------------
	get: (key) ->
		return @undefined unless isString( key )
		return ko.utils.unwrapObservable( @[key] )
	#END get

	#--------------------------------------------------------
	# Method: Falcon.Model#set()
	#	Sets a value for the specific key, creating one if it does nto exist
	#
	# Arguments:
	#	**key** _(string)_ - The key to look up
	#	**value** -(mixed)_ - The value to assign
	#
	# Arguments:
	#	**key** _(object)_ - An object of values to set
	#
	# Returns:
	#	_(Falcon.Model)_ - This Model
	#--------------------------------------------------------
	set: (key, value) ->
		if isObject( key )
			@set(k, v) for k, v of key
			return this
		#END if
		
		return this unless isString( key )
		
		if ko.isObservable( @[key] )
			@[key](value)
		else
			@[key] = value
		#END if

		return this
	#END set

	#--------------------------------------------------------
	# Method: Falcon.Model#toggle()
	#	Toggles the value between true/false on the specific key
	#
	# Arguments:
	#	**key** _(string)_ - The key to look up
	#
	# Returns:
	#	_(mixed)_ - The unwrapped value at the specific key
	#--------------------------------------------------------
	toggle: (key) ->
		return @set(key, not @get(key) )
	#END toggle

	#----------------------------------------------------------------------------------------------
	# Method: Falcon.Model#parse()
	#	parses the response data from an XHR request
	#
	# Arguments:
	#	**data** _(Object)_ - The xhr response data
	#	**options** _ - The options fed initially into the XHR request
	#	**xhr** _(Object)_ - The XHR object
	#
	# Returns:
	#	_Object_ - Parsing on a model expects an object to be returned
	#----------------------------------------------------------------------------------------------
	parse: (data, options, xhr) ->
		return data
	#END parse

	#--------------------------------------------------------
	# Method: Falcon.Model#fill()
	#	Method used to 'fill in' and add data to this model
	#
	# Arguments:
	#	**data** _(Object)_ - The data to fill
	#
	# Returns:
	#	_(Falcon.Model)_ - This instance
	#--------------------------------------------------------
	fill: (data) ->
		data = {'id': data} if isNumber(data) or isString(data)
		return this unless isObject(data)
		data = data.unwrap() if Falcon.isModel(data)
		return this if isEmpty( data )

		_data = {}

		#REMOVE
		#if the fields is an object, map the _data
		if isObject(@fields) and not isEmpty(@fields)
			_data[ @fields[key] ? key ] = value for key, value of data
		#Otherwise just directly map it
		else
			_data = data
		#END if

		rejectedKeys = {}
		for key, value of Falcon.Model.prototype when key not in ["id", "url"]
			rejectedKeys[key] = true
		#END for

		for key, value of _data when not rejectedKeys[key]
			value = ko.utils.unwrapObservable( value )
			if Falcon.isModel(this[key])
				this[key].fill(value) unless isEmpty( value )
			else if Falcon.isCollection(this[key])
				this[key].fill(value) unless isEmpty( value ) and this[key].length() <= 0
			else if ko.isObservable(this[key])
				this[key](value) if ko.isWriteableObservable(this[key])
			else
				this[key] = value
			#END if
		#END for

		return this
	#END fill

	#--------------------------------------------------------
	# Method: Falcon.Model#unwrap()
	#	Method used to 'unwrap' this object into a raw object
	#	Needed to cascade inwards on other Falcon Data objects (like lists)
	#	to unwrap newly added member variables/objects
	#
	# Returns
	#	_(Object)_ - The 'unwrapped' object
	#--------------------------------------------------------
	unwrap: () ->
		raw = {}

		#Get the keys that pertain only to this models added attributes
		keys = arrayRemove( objectKeys(this), objectKeys(Falcon.Model.prototype) )
		keys[keys.length] = "id"

		for key in keys
			value = this[key]
			raw[key] = if Falcon.isDataObject(value) then value.unwrap() else value
		#END for

		return raw
	#END unwrap

	#--------------------------------------------------------
	# Method: Falon.Model#serialize()
	#	Serializes the data into a raw json object and only corresponds to the fields
	#	that are primitive and that we wish to be able to send back to the server
	#
	# Arguments:
	#	**fields** _(Araay)_ -	The fields that should be included in the 
	#	                      	serialization "id" is always included. If 
	#	                      	none given, all fields from this models 'fields' 
	#	                      	member are serialized
	#
	#	**deep** _(Boolean)_ -	should we do a deep copy? In otherwords, should 
	#	                      	we cascade downwards to serialize data about 
	#	                      	children models.
	#
	# Returns:
	#	_(Object)_ - The resultant 'raw' object to send to the server
	#--------------------------------------------------------
	serialize: (fields, deep) ->
		raw = {}

		[deep, fields] = [fields, deep] if not isBoolean( deep ) and isBoolean( fields )
		deep = true unless isBoolean( deep )

		fields = null if isEmpty( fields )
		fields = trim(fields).split(",") if isString( fields )
		#ADD default fields to every acceptable attribute on this model
		#REMOVE
		unless fields?
			fields = @fields
			fields["id"] = "id" if isObject( fields ) and not fields["id"]?
			fields.push("id") if isArray( fields ) and "id" not in fields
		#END unless
		server_keys = []
		model_keys = []

		# Get the keys and mapped keys
		# Mapped keys are the local attributes
		# Keys are the server's attributes
		if isArray(fields) and not isEmpty(fields)
			if isObject(@fields) #TODO: Can we optimize this at all?
				for field in fields
					server_keys[server_keys.length] = findKey( @fields, field ) ? field
					model_keys[model_keys.length] = field
				#END for
			else
				for field in fields
					server_keys[server_keys.length] = field
					model_keys[model_keys.length] = field
				#END for
			#END if
		else if isObject(fields) and not isEmpty(fields)
			for server_field, model_field of fields
				server_keys[server_keys.length] = server_field
				model_keys[model_keys.length] = if model_field of this then model_field else server_field
			#END for

		else
			server_keys = model_keys = arrayRemove( objectKeys(this), objectKeys(Falcon.Model.prototype) )
		#END if

		#Make sure we pull in the id
		#server_keys.push("id") unless "id" in server_keys
		#model_keys.push("id") unless "id" in model_keys

		for index, model_key of model_keys
			server_key = server_keys[index]
			value = this[model_key]

			if Falcon.isDataObject(value)
				raw[server_key] =  if deep then value.serialize() else value.serialize(["id"])
			else if ko.isObservable(value)
				raw[server_key] = ko.utils.unwrapObservable( value )
			else if not isFunction(value)
				raw[server_key] = value
			#END if
		#END for

		return raw
	#END serialize
		
	#--------------------------------------------------------
	# Method: Falcon.Model#makeURL()
	#	generates a URL based on this model's url, the parent model of this model, 
	#	the type of request we're making and Falcon's defined baseApiUrl
	#
	# Arguments:
	#	**type** _(string)_ - The type of request we're making (GET, POST, PUT, DELETE)
	#
	# Returns:
	#	_String_ - The generated URL
	#--------------------------------------------------------
	makeUrl: (type, parent) ->
		url = if isFunction(@url) then @url() else @url
		url = "" unless isString(url)
		url = trim(url)

		type = "" unless isString(type)
		type = type.toUpperCase()
		type = 'GET' unless type in ['GET', 'PUT', 'POST', 'DELETE']

		parent = if parent isnt undefined then parent else @parent

		ext = ""
		periodIndex = url.lastIndexOf(".")

		#Split on the extension if it exists
		if periodIndex > -1
			ext = url.slice(periodIndex)
			url = url.slice(0, periodIndex)
		#END if

		#Make sure the url is now formatted correctly
		url = "/#{url}" unless startsWith(url, "/")

		#Check if a parent model is present
		if Falcon.isModel(parent)
			parentUrl = parent.makeUrl()
			parentPeriodIndex = parentUrl.lastIndexOf(".")
			parentSlashIndex = parentUrl.lastIndexOf("/")

			if parentSlashIndex < parentPeriodIndex
				parentUrl = parentUrl.slice(0, parentPeriodIndex) if parentPeriodIndex > -1
				parentUrl = trim(parentUrl)
			#END if

			url = "#{parentUrl}#{url}"

		#Otherwise consider this the base
		else if isString(Falcon.baseApiUrl)
			url = "#{Falcon.baseApiUrl}#{url}"

		#END if

		#Append the id if it exists
		if type in ["GET", "PUT", "DELETE"]
			url += "/" unless url.slice(-1) is "/"
			url += ko.utils.unwrapObservable( @id )
		#END if

		#Replace any double slashes outside of the initial protocol
		url = url.replace(/([^:])\/\/+/gi, "$1/")

		#Return the built url
		return "#{url}#{ext}"
	#END makeUrl

	#--------------------------------------------------------
	# Method: Falcon.Model#sync()
	#	Used to dynamically place calls to the server in order
	#	to create, update, destroy, or read this from/to the
	#	server
	#
	# Arguments:
	#	**type** _(String)_ - The HTTP Method to call to the server with
	#	**options** _(Object)_ - Optional object of settings to use on this call
	#
	# Returns:
	#	_(Falcon.Model)_ - This instance
	#--------------------------------------------------------
	sync: (type, options) ->
		options = {complete: options} if isFunction(options)
		options = {fields: trim( options ).split(",")} if isString(options)
		options = {fields: options} if isArray( options )

		options = {} unless isObject(options)
		options.data = {} unless isObject(options.data)
		options.dataType = "json" unless isString(options.dataType)
		options.contentType = "application/json" unless isString(options.contentType)
		options.success = (->) unless isFunction(options.success)
		options.complete = (->) unless isFunction(options.complete)
		options.error = (->) unless isFunction(options.error)
		options.parent = @parent unless Falcon.isModel(options.parent)
		options.fields = [] unless isArray( options.fields )
		options.params = {} unless isObject( options.params ) 
		options.fill = true unless isBoolean( options.fill )
		options.headers = {} unless isObject( options.headers )

		type = trim( if isString(type) then type.toUpperCase() else "GET" )
		type = "GET" unless type in ["GET", "POST", "PUT", "DELETE"]

		data = {}
		unless isEmpty(options.data)
			data[key] = value for key, value of options.data
		#END unless

		data = extend(@serialize( options.fields ), data) if type in ["POST", "PUT"]

		#serialize the data to json
		json = if isEmpty(data) then "" else JSON.stringify(data)

		url = options.url ? @makeUrl(type, options.parent)

		unless isEmpty( options.params )
			url += "?" unless url.indexOf("?") > -1
			url += ( "#{key}=#{value}" for key, value of options.params ).join("&")
		#END if params

		return $.ajax
			'type': type
			'url': url
			'data': json
			'dataType': options.dataType
			'contentType': options.contentType
			'cache': Falcon.cache
			'headers': options.headers

			'success': (data, status, xhr) =>
				data = JSON.parse( data ) if isString( data )
				data = JSON.parse( xhr.responseText ) if not data? and isString( xhr.responseText )
				data ?= {}

				data = @parse( data, options, xhr )

				@fill(data, options) if options.fill

				switch type
					when "GET" then @trigger("fetch", data)
					when "POST" then @trigger("create", data)
					when "PUT" then @trigger("save", data)
					when "DELETE" then @trigger("destroy", data)
				#END switch

				options.success.call(this, this, data, status, xhr)
			#END success

			'error': (xhr) => 
				response = xhr.responseText
				try
					response = JSON.parse(response) if isString(response)
				catch e

				options.error.call(this, this, response, xhr)
			#END error

			'complete': (xhr, status) =>
				options.complete.call(this, this, xhr, status)
			#END complete
		#END $.ajax
	#END sync

	#--------------------------------------------------------
	# Method: Falcon.Model#fetch()
	#	Calls the sync method with 'GET' as the default type
	#	server. Get's this model's server data.
	#
	# Arguments:
	#	**options** _(Object)_ - Optional object of settings to use on this call
	#
	# Returns:
	#	_(Falcon.Model)_ - This instance
	#--------------------------------------------------------
	fetch: (options) -> 
		return @sync('GET', options)
	#END fetch

	#--------------------------------------------------------
	# Method: Falcon.Model#create()
	#	Calls the sync method with 'POST' as the default type
	#	server. Creates a new version of this model.
	#
	# Arguments:
	#	**options** _(Object)_ - Optional object of settings to use on this call
	#
	# Returns:
	#	_(Falcon.Model)_ - This instance
	#--------------------------------------------------------
	create: (options) -> 
		return @sync('POST', options)
	#END create

	#--------------------------------------------------------
	# Method: Falcon.Model#save()
	#	Calls the sync method with 'PUT' as the default type
	#	server. Saves this model to the server.
	#
	# Arguments:
	#	**options** _(Object)_ - Optional object of settings to use on this call
	#
	# Returns:
	#	_(Falcon.Model)_ - This instance
	#--------------------------------------------------------
	save: (options) -> 
		return @sync('PUT', options)
	#END save

	#--------------------------------------------------------
	# Method: Falcon.Model#destroy()
	#	Calls the sync method with 'DELETE' as the default type
	#	server.  Deletes this model from the server.
	#
	# Arguments:
	#	**options** _(Object)_ - Optional object of settings to use on this call
	#
	# Returns:
	#	_(Falcon.Model)_ - This instance
	#--------------------------------------------------------
	destroy: (options) -> 
		return @sync('DELETE', options)
	#END destroy

	#--------------------------------------------------------
	# Method: Falcon.Model#equals()
	#	Determines if this model is equivalent to the input value
	#
	# Arguments 1:
	#	**model** _(Falcon.Model)_ - Is this model the same as the one given, based on id
	#
	# Arguments 2:
	#	**id** _(Number)_ - Treated as an id, checked against this id
	#
	# Returns:
	#	_(Boolean)_ - Are these equal?
	#--------------------------------------------------------
	equals: (model) ->
		model = ko.utils.unwrapObservable( model )

		if Falcon.isModel( model )
			return model.get("id") is @get("id")
		else if isNumber( model ) or isString( model )
			return model is @get("id")
		#END if

		return false
	#END equals


	#--------------------------------------------------------
	# Method: Falcon.Model#mixin()
	#	Maps extra atributes and methods onto this model for use
	#	later, mostly in Falcon views. Will ensure that any method
	#	that is not a knockout observable will be called in the
	#	context of this model as well as pass this model in as
	#	the first argument, pushing the other arguments down the
	#	list.
	# 
	# Arguments:
	#	**mapping** _(Object)_ - The mapping to augment this model with
	#
	# Returns:
	#	_(Falcon.Model)_ - This model
	#
	# TODO:
	#	Have observables check for 'extends' method
	#--------------------------------------------------------
	mixin: (mapping) ->
		mapping = {} unless isObject(mapping)

		for key, value of mapping
			if Falcon.isDataObject( this[key] )
				this[key].mixin(value)
			else 
				if ko.isObservable(value)
					this[key] = ko.observable( ko.utils.unwrapObservable(value) )
				else if isFunction(value)
					do =>
						_value = value
						this[key] = (args...) => 
							_value.call(this, this, args...) 
						#END
					#END do
				else
					this[key] = value 
				#END if
			#END if
		#END for

		return this
	#END mixin

	#--------------------------------------------------------
	# Method: Falcon.Model#clone()
	#	Method used to deeply clone this model
	#
	# Arguments:
	#	**parent** _(Falcon.Model)_ - The parent of the clone. optional
	#
	# Returns:
	#	_Falcon.Model_ - A clone of this model
	#
	# TODO:
	#	Add deep cloning
	#--------------------------------------------------------
	clone: (parent) ->
		parent = if parent? or parent is null then parent else @parent
		return new @constructor(this.unwrap(), parent )
	#END clone

	#--------------------------------------------------------
	# Method: Falcon.Model#copy()
	#	Method used to copy this model
	#
	# Arguments:
	#	**fields** _(Array)_ - A list of attributes to copy.
	#	**parent** _(Object)_ - The parent to set on the new model, use 
	#							'null' to unset the parent.
	#
	# Returns:
	#	_(Falcon.Model)_ - A copy of this model
	#--------------------------------------------------------
	copy: (fields, parent) ->
		parent = fields if fields is null or Falcon.isModel( fields )
		fields = ["id"] unless isArray( fields )
		parent = @parent unless parent is null or Falcon.isModel( parent )
		return new @constructor( @serialize( fields ), parent )
	#END copy

	#--------------------------------------------------------
	# Method: Falcon.Model#isNew()
	#	Method used to check if this model is new or is from the server.  Based on id.
	#
	# Returns:
	#	_Boolean_ - Is this a new model?
	#--------------------------------------------------------
	isNew: () ->
		return ( not @get("id")? )
	#END isNew
#END Falcon.Model
