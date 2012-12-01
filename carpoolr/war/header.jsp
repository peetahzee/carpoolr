<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>
<%@ page import="java.util.List" %>
<%@ page import="com.google.appengine.api.users.User" %>
<%@ page import="com.google.appengine.api.users.UserService" %>
<%@ page import="com.google.appengine.api.users.UserServiceFactory" %>

<%
    UserService userService = UserServiceFactory.getUserService();
    User user = userService.getCurrentUser();
%>
<!DOCTYPE html>
<html>
	<head>
		<title>Project Carpoolr</title>
		<link href='http://fonts.googleapis.com/css?family=Open+Sans:400,300,700,800' rel='stylesheet' type='text/css'>
		<link href='assets/style.css' rel='stylesheet' type='text/css'>
		<link href='assets/jquery-css/jquery-ui-1.9.2.custom.css' rel='stylesheet' type='text/css'>
		<script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
		<script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jqueryui/1.9.1/jquery-ui.min.js"></script>
		<script type="text/javascript" src="assets/jquery.center.js"></script>
		<script type="text/javascript" src="assets/jquery-ui-timepicker-addon.js"></script>
		<script type="text/javascript" src="http://maps.googleapis.com/maps/api/js?libraries=places&key=AIzaSyBfwn19JCKZSWqDsjQjGaOATvIXccQYT-Y&sensor=true"></script>
	    <script type="text/javascript" src="assets/script.js"></script>
	    <script type="text/javascript">
		  var _gaq = _gaq || [];
		  _gaq.push(['_setAccount', 'UA-36654091-1']);
		  _gaq.push(['_setDomainName', 'ptzlabs.com']);
		  _gaq.push(['_trackPageview']);
		
		  (function() {
		    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
		    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
		    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
		  })();
		
		</script>
	</head>
	<body>
		<header>
			<a href="/"><div id="logo"></div></a>
			<div id="user">
				<% if(user != null) { %>
					<%=user.getEmail()%> <a href="<%=userService.createLogoutURL(request.getRequestURI())%>" id="logoutLink">(logout)</a>
				<% } else { %>
					not logged in.
				<% } %>
			</div>
		</header>
		<div id="content">
			<div id="map_canvas" style="width:100%; height:100%"></div>
		</div>