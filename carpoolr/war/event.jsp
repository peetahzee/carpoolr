<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>
<%@ page import="com.google.appengine.api.datastore.DatastoreService" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreServiceFactory" %>
<%@ page import="com.google.appengine.api.datastore.Entity" %>
<%@ page import="com.google.appengine.api.datastore.GeoPt" %>
<%@ page import="com.google.appengine.api.datastore.FetchOptions" %>
<%@ page import="com.google.appengine.api.datastore.Key" %>
<%@ page import="com.google.appengine.api.datastore.KeyFactory" %>
<%@ page import="com.google.appengine.api.datastore.Query" %>
<%@ page import="com.google.appengine.api.datastore.Query.Filter" %>
<%@ page import="com.google.appengine.api.datastore.Query.FilterOperator" %>
<%@ page import="com.google.appengine.api.datastore.Query.FilterPredicate" %>
<%@ page import="com.google.appengine.api.datastore.Query.SortDirection" %>
<%@ page import="com.google.appengine.api.datastore.PreparedQuery" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map.Entry" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.TimeZone" %>
<%@ page import="com.ptzlabs.carpoolr.CarpoolrServlet" %>

<%@ include file="header.jsp" %>
<%
DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();

Entity event;
if(request.getParameter("id") != null) {
    Key k = KeyFactory.createKey("event", Integer.valueOf(request.getParameter("id")));
    event = datastore.get(k);
} else {
    if(request.getParameter("code") == null) {
		%><script type="text/javascript">window.location = "/";</script><%
		return;
    }
	String eventCode = request.getParameter("code").toLowerCase();
	
	Filter eventCodeFilter = new FilterPredicate("code", FilterOperator.EQUAL, eventCode);
	Query q = new Query("event").setFilter(eventCodeFilter);
	PreparedQuery pq = datastore.prepare(q);
	event = pq.asSingleEntity();
}

if(event == null) {
    %><script type="text/javascript">window.location = "/";</script><%
    return;
}

Date createdDate = (Date) event.getProperty("time");
Date arrivalTime = (Date) event.getProperty("arrivalTime");
SimpleDateFormat dateFormatter = new SimpleDateFormat("E, MMM dd");
dateFormatter.setTimeZone(TimeZone.getTimeZone("GMT-8"));
SimpleDateFormat dateTimeFormatter = new SimpleDateFormat("E, MMM dd HH:mm");
dateTimeFormatter.setTimeZone(TimeZone.getTimeZone("GMT-8"));

User hostUser = (User) event.getProperty("user");

Filter eventIDFilter = new FilterPredicate("event", FilterOperator.EQUAL, event.getKey().getId());
Query q = new Query("rider").setFilter(eventIDFilter);
PreparedQuery pq = datastore.prepare(q);
List<Entity> riders = pq.asList(FetchOptions.Builder.withDefaults());

if(request.getParameter("nr") != null) {
    int newRiderID = Integer.valueOf(request.getParameter("nr"));
    Key k = KeyFactory.createKey("rider", newRiderID);
    Entity rider = datastore.get(k);
    if(!riders.contains(rider)) {
		riders.add(rider);
    }
}

q = new Query("driver").setFilter(eventIDFilter);
pq = datastore.prepare(q);
List<Entity> drivers = pq.asList(FetchOptions.Builder.withDefaults());

if(request.getParameter("nd") != null) {
    int newDriverID = Integer.valueOf(request.getParameter("nd"));
    Key k = KeyFactory.createKey("driver", newDriverID);
    Entity driver = datastore.get(k);
    if(!drivers.contains(driver)) {
		drivers.add(driver);
    }
}

int totalCapacity = 0;
boolean foundUser = false;
for(Entity driver : drivers) {
    totalCapacity += (Long) driver.getProperty("capacity");
    if(driver.getProperty("user").equals(user)) {
		foundUser = true;
    }
}
for(Entity rider : riders) {
    if(rider.getProperty("user").equals(user)) {
		foundUser = true;
    }
}
%>

	<script type="text/javascript">
		window.history.replaceState("updateEventUrl", "", "/event.jsp?code=<%=event.getProperty("code")%>")
		var eventOrigin = new google.maps.LatLng(<%=event.getProperty("origin")%>);
		var eventDestination = new google.maps.LatLng(<%=event.getProperty("destination")%>);
		
		var riderDetails = new Array();
		var driverDetails = new Array();
		
		var selectedDriver;
		
		var riders = new Array();
		var drivers = new Array();
		
		$(document).ready(function() {
			setMapOpacity(1);
			enableMapControls();
			
			showRoute(eventOrigin, eventDestination);
			loadData();
			loadUserLocations();
			addUserAvatarHandler();
			
			$(".backLink").click(function() {
				if($("ul#riders").is(":visible")) {
					$("ul#drivers").hide(300);
					$("ul#riders").hide(300, function() {
						$("#manageButton").click();
						$("ul#drivers").show(300);
					})
				} else {
					setMapOpacity(1);
					enableMapControls();
					clearOverlays();
					loadUserLocations();
					
					$(".dialog").hide(300, function() {
						$(".dialog > div").hide(0);
					});
					$(".event_details").show(300);
					
					showEventSummary();
					$("ul#drivers li a").unbind();
					$("ul#riders li a").unbind();
				}
			});
			
			$("#addRiderButton").click(function() {
				<% if(user == null) { %>
				  	window.location = "<%=userService.createLoginURL(request.getRequestURI() + "?code=" + request.getParameter("code"))%>";
				<% } else { %>
					setMapOpacity(0.7);
					clearOverlays();
					riderDetails = new Array();
					$(".event_details").hide(300);
					$("#addRider").show(0);
					$(".dialog").show(300);
					$("a.backLink").show(0);
				<% } %>
			});
			
			$("form#addRiderForm").submit(function(event) {
				var invalid = false;
    			$("form#addRiderForm input").each(function() {
    				$(this).removeClass("error");
    				if($(this).val() == "") { 
    					invalid = true;
    					$(this).addClass("error");
    				}
    				riderDetails[$(this).attr("name")] = $(this).val();
    			});
    			if(invalid) { return false; }
    			$("#addRider").hide(300);
    			$(".dialog").hide(300);
    			
    			askForLocation("Around where are you located?", "setAddRiderLocation");
    			
    			event.preventDefault();
    			return false;
			});
			
			$("#addDriverButton").click(function() {
				<% if(user == null) { %>
				  	window.location = "<%=userService.createLoginURL(request.getRequestURI() + "?code=" + request.getParameter("code"))%>";
				<% } else { %>
					setMapOpacity(0.7);
					clearOverlays();
					driverDetails = new Array();
					$(".event_details").hide(300);
					$("#addDriver").show(0);
					$(".dialog").show(300);
					$("a.backLink").show(0);
				<% } %>
			});
			
			$("form#addDriverForm").submit(function(event) {
				var invalid = false;
    			$("form#addDriverForm input").each(function() {
    				$(this).removeClass("error");
    				if($(this).val() == "" || ($(this).attr("name") == "driverCapacity" && isNaN($(this).val()))) { 
    					invalid = true;
    					$(this).addClass("error");
    				}
    				driverDetails[$(this).attr("name")] = $(this).val();
    			});
    			if(invalid) { return false; }
    			$("#addDriver").hide(300);
    			$(".dialog").hide(300);
    			
    			askForLocation("Around where will are you located?", "setAddDriverLocation");
    			
    			event.preventDefault();
    			return false;
			});
			
			$("#manageButton").click(function() {
				$("#event_summary").hide(300);
				$("#event_manage").show(300);
				$("a.backLink").show(0);
				dispDriverNames();
				selectedDriver = null;
				
				//init
				$("ul#drivers li").show();
				$("ul#drivers li a").show();
				$("ul#riders").hide();
				
				$("ul#drivers li a").click(function(e) {
					$("ul#drivers li").not($(this).parents("li")).hide(300);
					$(this).hide();
					
					selectedDriver = $(this).parents("li").attr("data-driverid");
					$("ul#riders").show(300);
					
					$("ul#riders li a").click(function(e) {
						var riderID = $(this).parents("li").attr("data-riderid");
						riders[riderID].pairedDriver = selectedDriver;
						$(this).parents("li").addClass("taken");
						$(this).hide(300);
						$(this).parent().siblings(".name").html(riders[riderID].name+ ", " +
								"paired with <span class=\"driverName\" data-driverID=\"" +selectedDriver +"\"></span>");
						dispDriverNames();
						$.post("/serv", {mode: "pairRider", driver: selectedDriver, rider: riderID})
						e.preventDefault();
						return false;
					});
				});
			})
			
			$("#shareButton").click(function() {
				setMapOpacity(0.7);
				clearOverlays();
				$(".event_details").hide(300);
				$("#shareEvent").show(0);
				$(".dialog").show(300);
				$("a.backLink").show(0);
			});
		});
		
		function setAddRiderLocation(lat, lng) {
			riderDetails['riderLocation'] = new google.maps.LatLng(lat, lng);
    		
    		resetMap();
    		
    		$("#riderNameConfirm").html(riderDetails['riderName']);
    		getAddressLatLng(riderDetails['riderLocation'], function(address) {
    			$("#riderLocationConfirm").html(address);	
    			$("input[name=riderLocationAddress]").val(address);
    		});
    		
    		$("input[name=riderName]").val(riderDetails['riderName']);
    		$("input[name=riderLocationLat]").val(riderDetails['riderLocation'].lat());
    		$("input[name=riderLocationLng]").val(riderDetails['riderLocation'].lng());
    		
    		$("#addRiderConfirm").show(0);
    		$(".dialog").show(300);
		}
		
		function setAddDriverLocation(lat, lng) {
			driverDetails['driverLocation'] = new google.maps.LatLng(lat, lng);
    		
    		resetMap();
    		
    		$("#driverNameConfirm").html(driverDetails['driverName']);
    		$("#driverCapacityConfirm").html(driverDetails['driverCapacity']);
    		getAddressLatLng(driverDetails['driverLocation'], function(address) {
    			$("#driverLocationConfirm").html(address);	
    			$("input[name=driverLocationAddress]").val(address);
    		});
    		
    		$("input[name=driverName]").val(driverDetails['driverName']);
    		$("input[name=driverCapacity]").val(driverDetails['driverCapacity']);
    		$("input[name=driverLocationLat]").val(driverDetails['driverLocation'].lat());
    		$("input[name=driverLocationLng]").val(driverDetails['driverLocation'].lng());
    		
    		$("#addDriverConfirm").show(0);
    		$(".dialog").show(300);
		}
		
		function loadUserLocations() {
			var riderLocation;
			<% for(Entity rider: riders) { %>
	    		createMarker(new google.maps.LatLng(<%=((GeoPt) rider.getProperty("location")).toString()%>), 
							"<%=rider.getProperty("name")%>", null, "<%=rider.getProperty("address")%>");
			<% } %>
			
			var driverLocation;
			<% for(Entity driver: drivers) { %>
	    		createMarker(new google.maps.LatLng(<%=((GeoPt) driver.getProperty("location")).toString()%>),
	    				"<%=driver.getProperty("address")%>", null, 
	    				"<%=driver.getProperty("name")%>, <%=driver.getProperty("capacity")%> spots", 
	    				"http://www.google.com/intl/en_us/mapfiles/ms/micons/blue-dot.png");
			<% } %>
		}
		
		function showEventSummary() {
			$("#event_manage").hide(300);
			$("#event_summary").show(300);
			$("a.backLink").hide(0);
		}
		
		function loadData() {
			<% for(Entity rider : riders) { %>
			riders[<%=rider.getKey().getId()%>] = {
				<% for(Entry prop : rider.getProperties().entrySet()) { %>
					<%=prop.getKey()%> : "<%=prop.getValue()%>",
				<% } %>
					location: new google.maps.LatLng(<%=rider.getProperty("location").toString()%>)
				};
			<% } %>
			
			<% for(Entity driver : drivers) { %>
			drivers[<%=driver.getKey().getId()%>] = {
				<% for(Entry prop : driver.getProperties().entrySet()) { %>
					<%=prop.getKey()%> : "<%=prop.getValue()%>",
				<% } %>
				location: new google.maps.LatLng(<%=driver.getProperty("location").toString()%>)
			};
			<% } %>
		}
		
		function dispDriverNames() {
			$(".driverName").each(function() {
				var id = $(this).attr("data-driverid");
				$(this).html(drivers[id].name);
			})
		}
		
		function addUserAvatarHandler() {
			$(".rider_avatar, ul#riders li").click(function() {
				var riderID = $(this).attr("data-riderid");
				//map.setCenter(riders[riderID].location);
				infoWindow.setContent("<b>" + riders[riderID].name + "</b><br />" + riders[riderID].address);
				infoWindow.setPosition(riders[riderID].location);
				infoWindow.open(map);
			});
			$(".driver_avatar, ul#drivers li").click(function() {
				var driverID = $(this).attr("data-driverid");
				// map.setCenter(drivers[driverID].location);
				infoWindow.setContent("<b>" + drivers[driverID].name + "</b><br />" + drivers[driverID].address);
				infoWindow.setPosition(drivers[driverID].location);
				infoWindow.open(map);
			});
		}
	</script>
	
	<div id="route_details" class="event_details">
		<h1><b><%=event.getProperty("name") %></b> [<%=event.getProperty("code") %>]</h1>
		<p>created by <%=hostUser.getEmail()%>, on <%=dateFormatter.format(createdDate)%><br />
		Arrive by: <%=dateTimeFormatter.format(arrivalTime) %></p>
			
		<div id="event_summary">
			<div id="avatars">
				<b><%=riders.size()%> riders:</b><br />
				<img src="http://www.google.com/intl/en_us/mapfiles/ms/micons/red-dot.png" />
				<% for(Entity rider: riders) { 
					User riderUser = (User) rider.getProperty("user");
				%>
				<img alt="<%=rider.getProperty("name")%>"
					 title="<%=rider.getProperty("name")%>"
					 class="rider_avatar"
					 data-riderid="<%=rider.getKey().getId()%>"
				     src="http://www.gravatar.com/avatar/<%=CarpoolrServlet.md5(riderUser.getEmail().toLowerCase())%>?d=identicon" />
				<% } %>
				
				<div class="clear"></div>
				
				<b><%=drivers.size()%> drivers, <%=totalCapacity %> seats:</b><br />
				<img src="http://www.google.com/intl/en_us/mapfiles/ms/micons/blue-dot.png" />
				<% for(Entity driver: drivers) { 
					User driverUser = (User) driver.getProperty("user");
				%>
				
				<img alt="<%=driver.getProperty("name")%>"
					 title="<%=driver.getProperty("name")%>"
					 class="driver_avatar"
					 data-driverid="<%=driver.getKey().getId()%>"
				     src="http://www.gravatar.com/avatar/<%=CarpoolrServlet.md5(driverUser.getEmail().toLowerCase())%>?d=identicon" />
				<% } %>
			</div>
		</div>
		
		<% if(user != null && user.equals(hostUser)) { %>
		<div id="event_manage" style="display: none;">
			<% if(drivers.size() == 0)  { %>
				<p>No drivers.</p>
			<% } else { %>
			<p>Select a driver from below, and assign riders to them.</p>
			<ul id="drivers" class="user_list">
				<% for(Entity driver: drivers) { 
					User driverUser = (User) driver.getProperty("user"); %>
					<li data-driverid="<%=driver.getKey().getId()%>">
						<img alt="<%=driver.getProperty("name")%>"
							 title="<%=driver.getProperty("name")%>"
				   			 src="http://www.gravatar.com/avatar/<%=CarpoolrServlet.md5(driverUser.getEmail().toLowerCase())%>?d=identicon" />
						<span class="name"><b><%=driver.getProperty("name") %></b>, <%=driver.getProperty("capacity")%> spots</span>
						<span class="action"><a href="javascript: void(0)">(select)</a></span>
						<div class="clear"></div>
					</li>
				<% } %>
			</ul>
			
			<ul id="riders" class="user_list" style="display: none;">
				<% for(Entity rider: riders) { 
					User riderUser = (User) rider.getProperty("user"); %>
					<li data-riderid="<%=rider.getKey().getId()%>"<%=(rider.getProperty("pairedDriver")!=null)?" class=\"taken\"":"" %>>
						<img alt="<%=rider.getProperty("name")%>"
							 title="<%=rider.getProperty("name")%>"
				   			 src="http://www.gravatar.com/avatar/<%=CarpoolrServlet.md5(riderUser.getEmail().toLowerCase())%>?d=identicon" />
				   		<% if (rider.getProperty("pairedDriver") == null) {%>
							<span class="name"><%=rider.getProperty("name") %>, <%=riderUser.getEmail()%></span>
							<span class="action"><a href="javascript: void(0)">(assign)</a></span>
						<% } else { %>
							<span class="name"><%=rider.getProperty("name") %>,
								paired with <span class="driverName" data-driverid="<%=rider.getProperty("pairedDriver")%>"></span></span>
						<% } %>
						<div class="clear"></div>
					</li>
				<% } %>
			</ul>
			<% } %>
			
			
			<% } %>
		</div>
		<a href="javascript: void(0)" style="display: none;" class="backLink">< back</a>
	</div>
	
	<div id="event_buttons" class="event_details">
		<% if(!foundUser) { %>
			<button id="addRiderButton">+ rider</button>
			<button id="addDriverButton">+ driver</button>
		<% } %>
		<% if(hostUser.equals(user)) { %><button id="manageButton">manage</button> <% } %>
		<button id="shareButton">share</button>
	</div>
	
	<div class="dialog" style="display: none;">
		<div id="addRider" style="display: none;">
			<h1 class="green">Join Event as Rider</h1>
			<p>Fill in your information and we'll try to find you a driver: </p>
			<form id="addRiderForm">
			<div class="input_wrapper">
				<label class="green">Name</label>
				<input type="text" name="riderName" placeholder="John Smith" />
			</div>
			<div class="input_wrapper">
				<label class="green"></label>
				<button id="addRiderNext">Next ></button>
			</div>
			</form>
		</div>
		
		<div id="addRiderConfirm" style="display: none;">
			<h1 class="green">Confirm Event</h1>
			<p>Here's what you entered:</p>
			<form id="addRiderConfirmForm" method="post" action="/serv">
			<div class="input_wrapper">
				<label class="green">Name</label>
				<div id="riderNameConfirm"></div>
				<input type="hidden" name="riderName" value="" />
			</div>
			<div class="input_wrapper">
				<label class="green">Location</label>
				<div id="riderLocationConfirm"></div>
				<input type="hidden" name="riderLocationLat" value="" />
				<input type="hidden" name="riderLocationLng" value="" />
				<input type="hidden" name="riderLocationAddress" value="" />
			</div>
			<div class="input_wrapper">
				<label class="green"></label>
				<input type="hidden" name="mode" value="addRider" />
				<input type="hidden" name="event" value="<%=event.getKey().getId()%>" />
				<button id="addRiderConfirmButton">Confirm ></button>
			</div>
			</form>
		</div>
		
		<div id="addDriver" style="display: none;">
			<h1 class="red">Join Event as Driver</h1>
			<p>Fill in your information and we'll get you registered as a driver: </p>
			<form id="addDriverForm">
			<div class="input_wrapper">
				<label class="red">Name</label>
				<input type="text" name="driverName" placeholder="John Smith" />
			</div>
			<div class="input_wrapper">
				<label class="red">Capacity</label>
				<input type="text" name="driverCapacity" placeholder="(other than you)" maxlength="1" />
			</div>
			<div class="input_wrapper">
				<label class="red"></label>
				<button id="addDriverNext" class="red">Next ></button>
			</div>
			</form>
		</div>
		
		<div id="addDriverConfirm" style="display: none;">
			<h1 class="red">Confirm Event</h1>
			<p>Here's what you entered:</p>
			<form id="addDriverConfirmForm" method="post" action="/serv">
			<div class="input_wrapper">
				<label class="red">Name</label>
				<div id="driverNameConfirm"></div>
				<input type="hidden" name="driverName" value="" />
			</div>
			<div class="input_wrapper">
				<label class="red">Capacity</label>
				<div id="driverCapacityConfirm"></div>
				<input type="hidden" name="driverCapacity" value="" />
			</div>
			<div class="input_wrapper">
				<label class="red">Location</label>
				<div id="driverLocationConfirm"></div>
				<input type="hidden" name="driverLocationLat" value="" />
				<input type="hidden" name="driverLocationLng" value="" />
				<input type="hidden" name="driverLocationAddress" value="" />
			</div>
			<div class="input_wrapper">
				<label class="red"></label>
				<input type="hidden" name="mode" value="addDriver" />
				<input type="hidden" name="event" value="<%=event.getKey().getId()%>" />
				<button id="addDriverConfirmButton" class="red">Confirm ></button>
			</div>
			</form>
		</div>
		
		<div id="shareEvent" style="display: none;">
			<h1 class="green">Share Event</h1>
			<p>Copy the link below and tell your friends to respond to the event:</p>
			<p><b>http://car.ptzlabs.com/event.jsp?code=<%=event.getProperty("code")%></b></p>
		</div>
		<a href="javascript:void(0)" class="backLink">< back</a>
	</div>
	
<%@ include file="footer.jsp" %>