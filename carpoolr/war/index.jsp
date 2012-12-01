<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>
    
<%@ include file="header.jsp" %>

	    <script type="text/javascript">
	    	var eventDetails = new Array();
	    	
	    	$(document).ready(function() {
	    		<% if(user != null) { %>
	    		$("#startEvent").click(function() {
	    			$("#welcomeScreen").hide(300, function() {
	    				$("#startEvent1").show(300);
	    				eventDetails = new Array();
	    				$("input[name=eventArrivalTime]").datetimepicker({
	    					dateFormat: "yy/mm/dd",
	    					timeFormat: "hh:mm tt",
	    					useLocalTimezone: true,
	    					defaultDate: new Date(),
	    					minDate: new Date(),
	    					stepMinute: 5,
	    					controlType: dateTimeControl
	    				});
	    			});
	    		});
	    		<% } else { %>
	    		$("#startEvent").click(function() {
	    			window.location = "<%=userService.createLoginURL(request.getRequestURI())%>";
	    		});
	    		<% } %>
	    		
	    		$("form#startEvent1Form").submit(function(event) {
	    			var invalid = false;
	    			$("form#startEvent1Form input").each(function() {
	    				$(this).removeClass("error");
	    				if($(this).val() == "") { 
	    					invalid = true;
	    					$(this).addClass("error");
	    				}
	    				eventDetails[$(this).attr("name")] = $(this).val();
	    			});
	    			if(invalid) { return false; }
	    			$("#startEvent1").hide(300);
	    			$(".dialog").hide(300);
	    			
	    			askForLocation("Around where will you start travelling?", "setStartEventOrigin");
	    			
	    			event.preventDefault();
	    			return false;
	    		});
	    	});
	    	
	    	function setStartEventOrigin(lat, lng) {
	    		eventDetails['eventOrigin'] = new google.maps.LatLng(lat, lng);
	    		
	    		resetMap();
	    		askForLocation("Search for your Destination...", "setStartEventDestination");
	    	}
	    	
	    	function setStartEventDestination(lat, lng) {
	    		eventDetails['eventDestination'] = new google.maps.LatLng(lat, lng);
	    		
	    		resetMap();
	    		
	    		$("#eventNameConfirm").html(eventDetails['eventName']);
	    		$("#eventArrivalTimeConfirm").html(eventDetails['eventArrivalTime']);
	    		getAddressLatLng(eventDetails['eventOrigin'], function(address) {
	    			$("#eventOriginConfirm").html(address);
	    			$("input[name=eventOriginAddress]").val(address);
	    		});
	    		getAddressLatLng(eventDetails['eventDestination'], function(address) {
	    			$("#eventDestinationConfirm").html(address);	
	    			$("input[name=eventDestinationAddress]").val(address);
	    		});
	    		
	    		$("input[name=eventName]").val(eventDetails['eventName']);
	    		$("input[name=eventArrivalTime]").val(eventDetails['eventArrivalTime']);
	    		$("input[name=eventOriginLat]").val(eventDetails['eventOrigin'].lat());
	    		$("input[name=eventOriginLng]").val(eventDetails['eventOrigin'].lng());
	    		$("input[name=eventDestinationLat]").val(eventDetails['eventDestination'].lat());
	    		$("input[name=eventDestinationLng]").val(eventDetails['eventDestination'].lng());
	    		
	    		$("#startEventConfirm").show(0);
	    		$(".dialog").show(300);
	    	}
	    </script>
		<div id="welcome" class="dialog">
			<div id="welcomeScreen">
			<div id="welcome_header"></div>
			<p>Tired of spending hours in figuring out the best way to pick people up, or finding your driver at the right time? We can help you organize carpooling more efficiently.</p>
			
			<div class="option" id="haveCode">
				<h4 class="green">I have a code</h4>
				<p>Somebody else started an event on Carpoolr and I'd like to join their event.</p>
				<form method="get" action="event.jsp">
					<input type="text" name="code" /><button>Go ></button>
				</form>
			</div>
			<div class="option" id="startEvent">
				<h4 class="blue">I want to start an event</h4>
				<p>I have an event coming up and I want to organize carpools.</p>
				<button class="blue">Start an event ></button>
			</div>
			</div>
			
			<div id="startEvent1" style="display: none;">
			<h1 class="blue">Start an event</h1>
				<p>Sweet! Fill in some details and we'll get you started right away.</p>
				<form id="startEvent1Form">
				<div class="input_wrapper">
					<label class="blue">Event name</label>
					<input type="text" name="eventName" placeholder="Eat at In n' Out" />
				</div>
				<div class="input_wrapper">
					<label class="blue">Target arrival time</label>
					<input type="text" name="eventArrivalTime" placeholder="Choose a time..." />
				</div>
				<div class="input_wrapper">
					<label class="blue"></label>
					<button class="blue" id="startEvent1Next">Next ></button>
				</div>
				</form>
			</div>
			
			<div id="startEventConfirm" style="display: none;">
			<h1 class="blue">Confirm Event</h1>
				<p>Here's what you entered:</p>
				<form id="startEventConfirmForm" method="post" action="/serv">
				<div class="input_wrapper">
					<label class="blue">Event name</label>
					<div id="eventNameConfirm"></div>
					<input type="hidden" name="eventName" value="" />
				</div>
				<div class="input_wrapper">
					<label class="blue">Target arrival time</label>
					<div id="eventArrivalTimeConfirm"></div>
					<input type="hidden" name="eventArrivalTime" value="" />
				</div>
				<div class="input_wrapper">
					<label class="blue">Start Location</label>
					<div id="eventOriginConfirm"></div>
					<input type="hidden" name="eventOriginLat" value="" />
					<input type="hidden" name="eventOriginLng" value="" />
					<input type="hidden" name="eventOriginAddress" value="" />
				</div>
				<div class="input_wrapper">
					<label class="blue">Destination</label>
					<div id="eventDestinationConfirm"></div>
					<input type="hidden" name="eventDestinationLat" value="" />
					<input type="hidden" name="eventDestinationLng" value="" />
					<input type="hidden" name="eventDestinationAddress" value="" />
				</div>
				<div class="input_wrapper">
					<label class="blue"></label>
					<input type="hidden" name="mode" value="startEvent" />
					<button class="blue" id="startEventConfirmButton">Confirm ></button>
				</div>
				</form>
			</div>
		</div>
<%@ include file="footer.jsp" %>