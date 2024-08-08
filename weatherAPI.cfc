component name="weatherAPI"{
	variables.api_base_url 	= "http://api.weatherapi.com";
	variables.api_version	= "v1"
	variables.content_type 	= "json"
	variables.api_key 		= "";
	// include air quality reports
	variables.aqi			= 0;
	// include weather alerts
	variables.alerts		= 0;

	public weatherAPI function init(
		required string api_key,
		string api_base_url,
		string api_version,
		string content_type,
		boolean aqi,
		boolean alerts
	){	
		for(local.key in arguments){
			if(arguments.keyExists(key) && arguments[key].len())
			variables[key] = arguments[key];
		}

		return this;
	}

	/**
	*	api_request() - main api request function
	*	@request_uri - api endpoint for weatherapi.com - https://www.weatherapi.com/docs/
	*	@method - http methods: post, get, put, patch, delete
	*	@request_params - array of structs in the format [{type="x", name="y", value="z"}]
	**/
	public struct function api_request (
		required string request_uri,
		required string method = "get",
		array request_params = []
	){
		local.return_data = {
			request: {
				uri: arguments.request_uri,
				params: arguments.request_params
			},
			success: false,
			errors: [],
			raw_response: {},
			response: {}
		};

		try {
			local.http_call = new HTTP(url=arguments.request_uri, method=arguments.method);
			local.http_call.addParam(type="header", name="Content-Type", value="application/#variables.content_type#");
			local.http_call.addParam(type="url", name="key", value=variables.api_key);

			// key never needs to be passed in, its always present
			for(local.param in arguments.request_params){
				local.http_call.addParam(type=local.param.type, name=local.param.name, value=local.param.value);
			}

			local.return_data.raw_response = local.http_call.send().getPrefix();
			local.return_data.response = (variables.content_type == "xml") ? xmlParse(local.return_data.raw_response.fileContent) : deserializeJSON(local.return_data.raw_response.fileContent);

			if(local.return_data.raw_response.keyExists("statusCode") && local.return_data.raw_response.statusCode.find("200")){
				local.return_data.success = true;
			}
			// check for response errors
			else if(local.return_data.response.keyExists("error")) {
				local.return_data.errors.append(local.return_data.response.error.code & " - " & local.return_data.response.error.message);
			}
		}
		catch(any err){
			local.return_data.errors.append(err.message & " - " & err.detail);
		}

		return local.return_data;
	}

	/**
	*	current() - current weather for a location
	*	@location - string for U.S zip code, U.K. zip code, IP Address, Latitude/Longitude
	**/
	public struct function current(
		required string location,
		boolean aqi = variables.aqi,
		boolean alerts = variables.alerts
	){
		return api_request(
			request_uri: generate_api_url(api_endpoint=getFunctionCalledName()),
			method: "get",
			request_params: [
								{type:"url", name:"q", value:arguments.location},
								{type:"url", name:"aqi", value:yesNoFormat(arguments.aqi)},
								{type:"url", name:"alerts", value:yesNoFormat(arguments.alerts)}
							]
		);
	}

	/**
	*	forecast() - forecast weather for a location
	*	@location - string for U.S zip code, U.K. zip code, IP Address, Latitude/Longitude
	**/
	public struct function forecast(
		required string location,
		numeric days = 1,
		boolean aqi = variables.aqi,
		boolean alerts = variables.alerts
	){
		return api_request(
			request_uri: generate_api_url(api_endpoint=getFunctionCalledName()),
			method: "get",
			request_params: [
								{type:"url", name:"q", value:arguments.location},
								{type:"url", name:"days", value:arguments.days},
								{type:"url", name:"aqi", value:yesNoFormat(arguments.aqi)},
								{type:"url", name:"alerts", value:yesNoFormat(arguments.alerts)}
							]
		);
	}

	/**
	*	history() - history of weather for a location, depends on paid plan type
	*	@location - string for U.S zip code, U.K. zip code, IP Address, Latitude/Longitude
	*	@dt - yyyy-MM-dd format between 14 and 300 days in the future or after 1/1/2010 in the past
	**/
	public struct function history(
		required string location,
		required string dt = now(),
		boolean aqi = variables.aqi,
		boolean alerts = variables.alerts
	){
		return api_request(
			request_uri: generate_api_url(api_endpoint=getFunctionCalledName()),
			method: "get",
			request_params: [
								{type:"url", name:"q", value:arguments.location},
								{type:"url", name:"aqi", value:yesNoFormat(arguments.aqi)},
								{type:"url", name:"alerts", value:yesNoFormat(arguments.alerts)},
								{type:"url", name:"dt", value:arguments.dt.dateFormat("yyyy-MM-dd")}
							]
		);
	}

	/**
	*	future() - future weather for a specific time span in a location
	*	@location - string for U.S zip code, U.K. zip code, IP Address, Latitude/Longitude
	*	@dt - For future API 'dt' should be between 14 days and 300 days from today in the future in yyyy-MM-dd format (i.e. dt=2023-01-01)
	**/
	public struct function future(
		required string location,
		required string dt,
		boolean aqi = variables.aqi,
		boolean alerts = variables.alerts
	){
		return api_request(
			request_uri: generate_api_url(api_endpoint=getFunctionCalledName()),
			method: "get",
			request_params: [
								{type:"url", name:"q", value:arguments.location},
								{type:"url", name:"dt", value:dateFormat(arguments.dt, "yyyy-MM-dd")},
								{type:"url", name:"aqi", value:yesNoFormat(arguments.aqi)},
								{type:"url", name:"alerts", value:yesNoFormat(arguments.alerts)}
							]
		);
	}

	/**
	*	marine() - marine/sailing weather for a location, depending on api membership level
	*	@location - string for U.S zip code, U.K. zip code, IP Address, Latitude/Longitude
	**/
	public struct function marine(
		required string location,
		boolean aqi = variables.aqi,
		boolean alerts = variables.alerts
	){
		return api_request(
			request_uri: generate_api_url(api_endpoint=getFunctionCalledName()),
			method: "get",
			request_params: [
								{type:"url", name:"q", value:arguments.location},
								{type:"url", name:"aqi", value:yesNoFormat(arguments.aqi)},
								{type:"url", name:"alerts", value:yesNoFormat(arguments.alerts)}
							]
		);
	}

	/**
	*	ip() - ip location, 
	*	@location - string for U.S zip code, U.K. zip code, IP Address, Latitude/Longitude
	**/
	public struct function ip(
		required string location,
		boolean aqi = variables.aqi,
		boolean alerts = variables.alerts
	){
		return api_request(
			request_uri: generate_api_url(api_endpoint=getFunctionCalledName()),
			method: "get",
			request_params: [
								{type:"url", name:"q", value:arguments.location},
								{type:"url", name:"aqi", value:yesNoFormat(arguments.aqi)},
								{type:"url", name:"alerts", value:yesNoFormat(arguments.alerts)}
							]
		);
	}

	/**
	*	astronomy() - astronomy information for a location, 
	*	@location - string for U.S zip code, U.K. zip code, IP Address, Latitude/Longitude
	**/
	public struct function astronomy(
		required string location,
		boolean aqi = variables.aqi,
		boolean alerts = variables.alerts
	){
		return api_request(
			request_uri: generate_api_url(api_endpoint=getFunctionCalledName()),
			method: "get",
			request_params: [
								{type:"url", name:"q", value:arguments.location},
								{type:"url", name:"aqi", value:yesNoFormat(arguments.aqi)},
								{type:"url", name:"alerts", value:yesNoFormat(arguments.alerts)}
							]
		);
	}

	/**
	*	generate_api_url() - generates the api endpoint uri, based on config and input
	*	@api_endpoint - the endpoint (without the file extension), ex: current, forecast, search
	**/
	private string function generate_api_url(
		required string api_endpoint
	){
		// attempt to self-correct url formatting on config
		return (variables.api_base_url.right(1) == "/") ? variables.api_base_url : variables.api_base_url & "/" 
		& ((variables.api_version.right(1) == "/") ? variables.api_version : variables.api_version & "/")
		& arguments.api_endpoint 
		& "." 
		& variables.content_type;
	}
}