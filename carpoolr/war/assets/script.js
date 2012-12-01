var map;
var placeService;
var directionsService
var directionsDisplay;
var geocoder;
var infoWindow;
var overlays = new Array();

$(document).ready(function() {
	initMaps();
	$("#welcome").center();
	$("#route_details").center({
		horizontal : false,
		vertical : false
	});
	$(".dialog").center();
})

function initMaps() {
	var mapOptions = {
		center : new google.maps.LatLng(-34.397, 150.644),
		zoom : 16,
		disableDefaultUI : true,
		mapTypeId : google.maps.MapTypeId.ROADMAP
	};
	map = new google.maps.Map(document.getElementById("map_canvas"), mapOptions);
	placeService = new google.maps.places.PlacesService(map);
	directionsService = new google.maps.DirectionsService();
	directionsDisplay = new google.maps.DirectionsRenderer();
	directionsDisplay.setMap(map);
	geocoder = new google.maps.Geocoder();
	infoWindow = new google.maps.InfoWindow();

	if (navigator.geolocation) {
		navigator.geolocation.getCurrentPosition(function(position) {
			var pos = new google.maps.LatLng(position.coords.latitude,
					position.coords.longitude);
			map.setCenter(pos);
		}, function() {
			handleNoGeolocation(true);
		});
	} else {
		// Browser doesn't support Geolocation
		handleNoGeolocation(false);
	}
}

function handleNoGeolocation(errorFlag) {
	if (errorFlag) {
		var content = 'Error: The Geolocation service failed.';
	} else {
		var content = 'Error: Your browser doesn\'t support geolocation.';
	}

	var options = {
		map : map,
		position : new google.maps.LatLng(60, 105),
		content : content
	};

	var infowindow = new google.maps.InfoWindow(options);
	map.setCenter(options.position);
}

function nearbyPlaces(targetFunction) {
	placeService.nearbySearch({
		location : map.getCenter(),
		radius : 20000
	}, function(results, status) {
		if (status == google.maps.places.PlacesServiceStatus.OK) {
			for ( var i = 0; i < results.length; i++) {
				var place = results[i];
				createMarkerWithPlace(place, targetFunction);
			}
		}
	})
}

function searchPlaces(keyword, targetFunction) {
	placeService.textSearch({
		location : map.getCenter(),
		radius : 20000,
		query : keyword
	}, function(results, status) {
		if (status == google.maps.places.PlacesServiceStatus.OK) {
			for ( var i = 0; i < results.length; i++) {
				var place = results[i];
				var marker = createMarkerWithPlace(place, targetFunction);
				if (i == 0) {
					google.maps.event.trigger(marker, 'click');
				}
			}
		}
		map.setCenter(results[0].geometry.location);
		setMapZoomLevel(16);
	})
}

function createMarkerWithPlace(place, targetFunction, extra, image) {
	return createMarker(place.geometry.location, place.name, targetFunction,
			extra);
}

function createMarker(location, name, targetFunction, extra, image) {
	var marker;
	if (image == null || image == undefined) {
		marker = new google.maps.Marker({
			map : map,
			position : location,
			title : name,
			animation : google.maps.Animation.DROP,
			zIndex : 100
		});
	} else {
		marker = new google.maps.Marker({
			map : map,
			position : location,
			title : name,
			icon : image,
			animation : google.maps.Animation.DROP,
			zIndex : 100
		});
	}

	overlays.push(marker);
	if (targetFunction == null || targetFunction == undefined) {
		google.maps.event.addListener(marker, 'click', function() {
			infoWindow.setContent("<b>" + name + "</b><br />" + extra);
			infoWindow.setPosition(location);
			infoWindow.open(map);
		});
	} else {
		google.maps.event.addListener(
				marker, 'click',function() {
					infoWindow.setContent("<b>"
					+ name
					+ "</b><br /><br /><a id=\"infoWindowLink\" href=\"javascript:void(0);\" onclick=\""
					+ targetFunction + location
					+ "\">Select location</a>");
					infoWindow.open(map, this);
		});
	}
	return marker;
}

function askForLocation(label, targetFunction) {
	$("#map_search p").hide(0);
	enableMapControls();
	setMapOpacity(1);

	$("#map_search").show(300);
	$("#map_search label").html(label);
	$("#map_search form").submit(function(event) {
		clearOverlays();
		var keyword = $(this).find("input").val();
		searchPlaces(keyword, targetFunction);
		$("#map_search p").show(300);
		event.preventDefault();
		return false;
	});
}

function resetMap() {
	setMapOpacity(0.7);
	disableMapControls();
	clearOverlays();
	$("#map_search input").val("");
	$("#map_search form").unbind();
	$("#map_search").hide(300);
}

function getAddressLatLng(latLng, callback) {
	geocoder.geocode({
		'latLng' : latLng
	}, function(results, status) {
		if (status == google.maps.GeocoderStatus.OK) {
			callback(results[0].formatted_address);
		} else {
			alert("Geocoder failed due to: " + status);
			callback("Unknown Address");
		}
	});
}

function getAddress(lat, lng, callback) {
	getAddressLatLng(new google.maps.LatLng(lat, lng), callback);
}

function disableMapControls() {
	map.setOptions({
		disableDefaultUI : true
	});
}

function enableMapControls() {
	map.setOptions({
		disableDefaultUI : false
	});
}

function setMapZoomLevel(zoom) {
	map.setOptions({
		zoom : zoom
	})
}

function clearOverlays() {
	for ( var i = 0; i < overlays.length; i++) {
		overlays[i].setMap(null);
	}
}

function showRoute(origin, destination) {
	var request = {
		origin : origin,
		destination : destination,
		travelMode : google.maps.TravelMode.DRIVING
	};
	directionsService.route(request, function(result, status) {
		if (status == google.maps.DirectionsStatus.OK) {
			directionsDisplay.setDirections(result);
			directionsDisplay
					.setPanel(document.getElementById("event_summary"));
			directionsDisplay.setOptions({
				markerOptions : {
					zIndex : 99
				},
				infoWindow : new google.maps.InfoWindow()
			})
			map.panBy(300, 0);
		}
	});

}

function setMapOpacity(opacity) {
	$("#content").css("opacity", opacity);
}

var dateTimeControl = {
	create : function(tp_inst, obj, unit, val, min, max, step) {
		$(
				'<input class="ui-timepicker-input" value="' + val
						+ '" style="width:50%">').appendTo(obj).spinner({
			min : min,
			max : max,
			step : step,
			change : function(e, ui) { // key events
				tp_inst._onTimeChange();
				tp_inst._onSelectHandler();
			},
			spin : function(e, ui) { // spin events
				tp_inst.control.value(tp_inst, obj, unit, ui.value);
				tp_inst._onTimeChange();
				tp_inst._onSelectHandler();
			}
		});
		return obj;
	},
	options : function(tp_inst, obj, unit, opts, val) {
		if (typeof (opts) == 'string' && val !== undefined)
			return obj.find('.ui-timepicker-input').spinner(opts, val);
		return obj.find('.ui-timepicker-input').spinner(opts);
	},
	value : function(tp_inst, obj, unit, val) {
		if (val !== undefined)
			return obj.find('.ui-timepicker-input').spinner('value', val);
		return obj.find('.ui-timepicker-input').spinner('value');
	}
};