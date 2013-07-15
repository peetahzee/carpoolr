<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"%>
<%@ page import="com.google.appengine.api.datastore.GeoPt" %>
<%@ page import="java.util.ArrayList"%>
<%@ page import="java.util.Date"%>
<%@ page import="java.util.List"%>
<%@ page import="java.util.Map.Entry"%>
<%@ page import="java.text.SimpleDateFormat"%>
<%@ page import="java.util.TimeZone"%>
<%@ page import="com.ptzlabs.carpoolr.Config"%>
<%@ page import="com.ptzlabs.carpoolr.Driver"%>
<%@ page import="com.ptzlabs.carpoolr.Event"%>
<%@ page import="com.ptzlabs.carpoolr.People"%>
<%@ page import="com.ptzlabs.carpoolr.Rider"%>
<%@ page import="com.ptzlabs.carpoolr.Utils"%>
<%@ page import="com.ptzlabs.carpoolr.servlets.CarpoolrServlet"%>
<%@ page import="com.ptzlabs.carpoolr.servlets.JspServlet"%>

<%@ include file="header.jsp"%>
<% Event event;
	if(request.getParameter("id") != null) {
	    event = JspServlet.getEvent(Long.valueOf(request.getParameter("id")));
	} else {
	    if(request.getParameter("code") == null) {
			out.print(JspServlet.redirectHomepage());
			return;
	    }
	    event = JspServlet.getEvent(request.getParameter("code"));
	}
	
	if(event == null) {
	    out.print(JspServlet.redirectHomepage());
	    return;
	}
	
	Date createdDate = event.time;
	Date arrivalTime = event.arrivalTime;
	SimpleDateFormat dateFormatter = new SimpleDateFormat("E, MMM dd");
	dateFormatter.setTimeZone(TimeZone.getTimeZone("GMT-8"));
	SimpleDateFormat dateTimeFormatter = new SimpleDateFormat("E, MMM dd HH:mm");
	dateTimeFormatter.setTimeZone(TimeZone.getTimeZone("GMT-8"));
	
	List<People> people = JspServlet.getPeople(event.id);
	List<Driver> drivers = new ArrayList<Driver>();
	List<Rider> riders = new ArrayList<Rider>();
	
	if(request.getParameter("nr") != null) {
	    people.add(JspServlet.getRider(Integer.valueOf(request.getParameter("nr"))));
	}
	
	if(request.getParameter("nd") != null) {
		people.add(JspServlet.getDriver(Integer.valueOf(request.getParameter("nd"))));
	}
	
	int totalCapacity = 0;
	int numRiders = 0;
	int numDrivers = 0;
	boolean foundUser = false;
	
	for(People p : people) {
		if(p instanceof Driver) {
			totalCapacity += ((Driver) p).capacity;
			drivers.add((Driver) p);
			numDrivers++;
		} else if (p instanceof Rider) {
			numRiders++;
			riders.add((Rider) p);
		}
		if(p.user.equals(user)) {
			foundUser = true;
		}
	}
%>

<script type="text/javascript">
		window.history.replaceState("updateEventUrl", "", "/event.jsp?code=<%=event.code%>")
		var eventOrigin = new google.maps.LatLng(<%=event.origin%>);
		var eventDestination = new google.maps.LatLng(<%=event.destination%>);
		
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
				<%if(user == null) {%>
				  	window.location = "<%=userService.createLoginURL(request.getRequestURI() + "?code=" + request.getParameter("code"))%>";
				<%} else {%>
					setMapOpacity(0.7);
					clearOverlays();
					riderDetails = new Array();
					$(".event_details").hide(300);
					$("#addRider").show(0);
					$(".dialog").show(300);
					$("a.backLink").show(0);
				<%}%>
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
				<%if(user == null) {%>
				  	window.location = "<%=userService.createLoginURL(request.getRequestURI() + "?code=" + request.getParameter("code"))%>";
				<%} else {%>
					setMapOpacity(0.7);
					clearOverlays();
					driverDetails = new Array();
					$(".event_details").hide(300);
					$("#addDriver").show(0);
					$(".dialog").show(300);
					$("a.backLink").show(0);
				<%}%>
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
			<% for (Driver d : drivers) { %>
				createMarker(new google.maps.LatLng(<%=d.location.toString()%>), "<%=d.address%>", null, "<%=d.name%>, <%=d.capacity%> spots", <%=Config.IMG_BLUE_DOT%>);
			<% } %>
			<% for (Rider r : riders) { %>
				createMarker(new google.maps.LatLng(<%=r.location.toString()%>), "<%=r.name%>", null, "<%=r.address%>");
			<% } %>
		}
		
		function showEventSummary() {
			$("#event_manage").hide(300);
			$("#event_summary").show(300);
			$("a.backLink").hide(0);
		}
		
		function loadData() {
			<% for(People p : people) { %>
				var p = {
					address: "<%=p.address%>",
					location: new google.maps.LatLng(<%=p.location.toString()%>,
					names: "<%=p.name%>",
					time: "<%=p.time.toString()%>",
					user: "<%=p.user.getEmail()%>"
				}
				<% if(p instanceof Driver) { %>
					drivers[<%=p.id%>] = p;
				<% } else if (p instanceof Rider) { %>
					riders[<%=p.id%>] = p;
				<% } %>
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
	<h1>
		<b><%=event.name%></b> [<%=event.code%>]
	</h1>
	<p>
		created by
		<%=event.user.getEmail()%>, on
		<%=dateFormatter.format(createdDate)%><br /> Arrive by:
		<%=dateTimeFormatter.format(arrivalTime)%></p>

	<div id="event_summary">
		<div id="avatars">
			<b><%=numRiders%> riders:</b><br /><img src="<%=Config.IMG_RED_DOT%>" />
			<% for (Rider r : riders) {
				out.print(r.getAvatar());
			} %>

			<div class="clear"></div>

			<b><%=numDrivers%> drivers, <%=totalCapacity%> seats:</b><br /><img src="<%=Config.IMG_BLUE_DOT%>" />
			<% for (Driver d : drivers) {
				out.print(d.getAvatar());
			} %>
		</div>
	</div>

	<% if (user != null && user.equals(event.user)) { %>
	<div id="event_manage" style="display: none;">
		<% if (numDrivers == 0) { %>
		
			<p>No drivers.</p>
		
		<% } else { %>
			<p>Select a driver from below, and assign riders to them.</p>
			<ul id="drivers" class="user_list">
				<% for (Driver d : drivers) {%>
					<li data-driverid="<%=d.id%>">
						<%=d.getAvatar()%>
						<span class="name"><b><%=d.name%></b>, <%=d.capacity%> spots</span>
						<span class="action"><a href="javascript: void(0)">(select)</a></span>
						<div class="clear"></div>
					</li>
				<% } %>
			</ul>
	
			<ul id="riders" class="user_list" style="display: none;">
				<% for (Rider r : riders) { %>
					<li data-riderid="<%=r.id%>" <%=(r.pairedDriver != null) ? " class=\"taken\"" : ""%>>
						<%=r.getAvatar()%>
						<% if (r.pairedDriver == null) { %>
							<span class="name"><%=r.name%>, <%=r.user.getEmail()%></span>
							<span class="action"><a href="javascript: void(0)">(assign)</a></span>
						<% } else { %>
							<span class="name"><%=r.name%>, paired with <span class="driverName" data-driverid="<%=r.pairedDriver%>"></span></span>
						<% } %>
						<div class="clear"></div>
					</li>
				<% } %>
			</ul>
		<% } %>
	</div>
	<% } %>
	<a href="javascript: void(0)" style="display: none;" class="backLink">back</a>
</div>

<div id="event_buttons" class="event_details">
	<% if (!foundUser) { %>
		<button id="addRiderButton">+ rider</button>
		<button id="addDriverButton">+ driver</button>
	<% } %>
	<% if (event.user.equals(user)) { %>
		<button id="manageButton">manage</button>
	<% } %>
	<button id="shareButton">share</button>
</div>

<div class="dialog" style="display: none;">
	<div id="addRider" style="display: none;">
		<h1 class="green">Join Event as Rider</h1>
		<p>Fill in your information and we'll try to find you a driver:</p>
		<form id="addRiderForm">
			<div class="input_wrapper">
				<label class="green">Name</label>
				<input type="text" name="riderName" placeholder="John Smith" />
			</div>
			<div class="input_wrapper">
				<label class="green"></label>
				<button id="addRiderNext">Next &gt;</button>
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
					<input type="hidden" name="event" value="<%=event.id%>" />
				<button id="addRiderConfirmButton">Confirm &gt;</button>
			</div>
		</form>
	</div>

	<div id="addDriver" style="display: none;">
		<h1 class="red">Join Event as Driver</h1>
		<p>Fill in your information and we'll get you registered as a
			driver:</p>
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
				<button id="addDriverNext" class="red">Next &gt;</button>
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
					<input type="hidden" name="event" value="<%=event.id%>" />
				<button id="addDriverConfirmButton" class="red">Confirm &gt;</button>
			</div>
		</form>
	</div>

	<div id="shareEvent" style="display: none;">
		<h1 class="green">Share Event</h1>
		<p>Copy the link below and tell your friends to respond to the event:</p>
		<p><b><%=event.getEventLink()%></b></p>
	</div>
	<a href="javascript:void(0)" class="backLink">&lt; back</a>
</div>

<%@ include file="footer.jsp"%>