package com.ptzlabs.carpoolr;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Properties;

import javax.mail.MessagingException;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.AddressException;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.appengine.api.datastore.DatastoreService;
import com.google.appengine.api.datastore.DatastoreServiceFactory;
import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.GeoPt;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;
import com.google.appengine.api.users.User;
import com.google.appengine.api.users.UserService;
import com.google.appengine.api.users.UserServiceFactory;

@SuppressWarnings("serial")
public class CarpoolrServlet extends HttpServlet {
    
    public void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
	resp.setContentType("text/plain");
	resp.getWriter().println("Hello, world");
    }
    
    public void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
	DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
	UserService userService = UserServiceFactory.getUserService();
	User user = userService.getCurrentUser();
	if(req.getParameter("mode").equals("startEvent")) {

	    String code = md5(new Date().getTime() + "ptzHello").substring(0, 5);
	    SimpleDateFormat formatter = new SimpleDateFormat("yyyy/MM/dd HH:mm z");
	    Date eventArrivalTime;
	    try {
		eventArrivalTime = formatter.parse(req.getParameter("eventArrivalTime"));
	    } catch (ParseException e) {
		eventArrivalTime = new Date();
	    }
	    
	    Entity event = new Entity("event");
	    event.setProperty("code", code);
	    event.setProperty("name", req.getParameter("eventName"));
	    event.setProperty("arrivalTime", eventArrivalTime);
	    event.setProperty("user", user);
	    event.setProperty("origin", new GeoPt(Float.valueOf(req.getParameter("eventOriginLat")),
		    Float.valueOf(req.getParameter("eventOriginLng"))));
	    event.setProperty("originAddress", req.getParameter("eventOriginAddress"));
	    event.setProperty("destination", new GeoPt(Float.valueOf(req.getParameter("eventDestinationLat")),
		    Float.valueOf(req.getParameter("eventDestinationLng"))));
	    event.setProperty("destinationAddress", req.getParameter("eventDestinationAddress"));
	    event.setProperty("time", new Date());
	    Key k = datastore.put(event);
	    
	    resp.sendRedirect("/event.jsp?id=" + k.getId());

	    String msgBody = "<h1>New event at Project Carpoolr</h1>"
		    + "<p>Hi there,</p>"
		    + "<p>Thanks for creating your event <b>"
		    + req.getParameter("eventName")
		    + "</b> at Project Carpoolr!</p>"
		    + "<p>You may now share this event with your friends and plan a carpool together by copying the link below. Thanks for using Carpoolr!</p>"
		    + "<p><b>http://car.ptzlabs.com/event.jsp?code=" + code + "</b></p>" + "<p>Project Carpoolr.</p>";

	    sendMessage("You have just created a new event at Project Carpoolr", msgBody, user.getEmail(),
		    user.getNickname());

	} else if (req.getParameter("mode").equals("addRider")) {

	    Key k = KeyFactory.createKey("event", Integer.valueOf(req.getParameter("event")));
	    Entity event;

	    try {
		event = datastore.get(k);
	    } catch (Exception e) {
		e.printStackTrace();
		resp.sendRedirect("/");
		return;
	    }

	    Entity rider = new Entity("rider");
	    rider.setProperty("event", Integer.valueOf(req.getParameter("event")));
	    rider.setProperty("name", req.getParameter("riderName"));
	    rider.setProperty("user", user);
	    rider.setProperty(
		    "location",
		    new GeoPt(Float.valueOf(req.getParameter("riderLocationLat")), Float.valueOf(req
			    .getParameter("riderLocationLng"))));
	    rider.setProperty("address", req.getParameter("riderLocationAddress"));
	    rider.setProperty("time", new Date());
	    k = datastore.put(rider);

	    String msgBody = "<h1>You signed up for a ride</h1>"
		    + "<p>Hi there, "
		    + req.getParameter("riderName")
		    + ",</p>"
		    + "<p>Thanks for signing up for a ride for <b>"
		    + event.getProperty("name")
		    + "</b> at Project Carpoolr!</p>"
		    + "<p>While we're stil trying to get you a ride, share the event with your friends by copying the link below!</p>"
		    + "<p><b>http://car.ptzlabs.com/event.jsp?code=" + event.getProperty("code") + "</b></p>"
		    + "<p>Project Carpoolr.</p>";

	    sendMessage(event.getProperty("name") + ": Ride registration successful", msgBody, user.getEmail(),
		    user.getNickname());

	    resp.sendRedirect("/event.jsp?code=" + event.getProperty("code") + "&nr=" + k.getId());


	} else if (req.getParameter("mode").equals("addDriver")) {

	    Key k = KeyFactory.createKey("event", Integer.valueOf(req.getParameter("event")));
	    Entity event;
	    
	    try {
		event = datastore.get(k);
	    } catch (Exception e) {
		e.printStackTrace();
		resp.sendRedirect("/");
		return;
	    }

	    Entity driver = new Entity("driver");
	    driver.setProperty("event", Integer.valueOf(req.getParameter("event")));
	    driver.setProperty("name", req.getParameter("driverName"));
	    driver.setProperty("capacity", Integer.valueOf(req.getParameter("driverCapacity")));
	    driver.setProperty("user", user);
	    driver.setProperty(
		    "location",
		    new GeoPt(Float.valueOf(req.getParameter("driverLocationLat")), Float.valueOf(req
			    .getParameter("driverLocationLng"))));
	    driver.setProperty("address", req.getParameter("driverLocationAddress"));
	    driver.setProperty("time", new Date());
	    k = datastore.put(driver);

	    String msgBody = "<h1>You signed up to drive</h1>"
		    + "<p>Hi there, "
		    + req.getParameter("driverName")
		    + ",</p>"
		    + "<p>Thanks for signing up for to be a driver for <b>"
		    + event.getProperty("name")
		    + "</b> at Project Carpoolr!</p>"
		    + "<p>While we're stil trying to organize rides, share the event with your friends by copying the link below!</p>"
		    + "<p><b>http://car.ptzlabs.com/event.jsp?code=" + event.getProperty("code") + "</b></p>"
		    + "<p>Project Carpoolr.</p>";

	    sendMessage(event.getProperty("name") + ": Driver registration successful", msgBody, user.getEmail(),
		    user.getNickname());

	    resp.sendRedirect("/event.jsp?code=" + event.getProperty("code") + "&nd=" + k.getId());

	} else if (req.getParameter("mode").equals("pairRider")) {
	    Key rk = KeyFactory.createKey("rider", Integer.valueOf(req.getParameter("rider")));
	    Key dk = KeyFactory.createKey("driver", Integer.valueOf(req.getParameter("driver")));
	    Key ek;
	    Entity rider, driver, event;

	    try {
		rider = datastore.get(rk);
		driver = datastore.get(dk);
		ek = KeyFactory.createKey("event", (Long) rider.getProperty("event"));
		event = datastore.get(ek);
	    } catch (Exception e) {
		e.printStackTrace();
		resp.sendRedirect("/");
		return;
	    }

	    if (driver == null || rider == null || event == null) {
		resp.sendRedirect("/");
		return;
	    }

	    rider.setProperty("pairedDriver", Integer.valueOf(req.getParameter("driver")));
	    datastore.put(rider);

	    String msgBody = "<h1>You just got a ride!</h1>" + "<p>Hi there, " + rider.getProperty("name") + ",</p>"
		    + "<p>Thanks for your patience! For your event <b>" + event.getProperty("name")
		    + "</b>, we have successfully found you a ride from <b>" + driver.getProperty("name") + "</b>.</p>"
		    + "<p>Enjoy your trip!</p>" + "<p>More details can be found at: <b>"
		    + "http://car.ptzlabs.com/event.jsp?code=" + event.getProperty("code") + "</b></p>"
		    + "<p>Project Carpoolr.</p>";
	    sendMessage(event.getProperty("name") + ": You just got a ride!", msgBody,
		    ((User) rider.getProperty("user")).getEmail(), ((User) rider.getProperty("user")).getNickname());

	    msgBody = "<h1>You just got paired with a rider!</h1>" + "<p>Hi there, "
		    + driver.getProperty("name") + ",</p>"
		    + "<p>Thanks for your patience and signing up to be a dirver for <b>" + event.getProperty("name")
		    + "</b> at Project Carpoolr! We have successfully paired you with rider <b>"
		    + rider.getProperty("name") + "</b>.</p>" + "<p>Enjoy your trip!</p>"
		    + "<p>More details can be found at: " + "<b>http://car.ptzlabs.com/event.jsp?code="
		    + event.getProperty("code") + "</b></p>" + "<p>Project Carpoolr.</p>";
	    sendMessage(event.getProperty("name") + ": You just got paired with a rider!", msgBody,
		    ((User) driver.getProperty("user")).getEmail(), ((User) driver.getProperty("user")).getNickname());

	    resp.getWriter().println("OK");
	} else {
	    resp.sendRedirect("/");
	}
    }
    
    public static String md5(String input) {
	String md5 = null;
	if (null == input)
	    return null;
	try {
	    // Create MessageDigest object for MD5
	    MessageDigest digest = MessageDigest.getInstance("MD5");

	    // Update input string in message digest
	    digest.update(input.getBytes(), 0, input.length());

	    // Converts message digest value in base 16 (hex)
	    md5 = new BigInteger(1, digest.digest()).toString(16);
	} catch (NoSuchAlgorithmException e) {
	    e.printStackTrace();
	}
	return md5;
    }

    public static void sendMessage(String title, String msgBody, String email, String name) {
	Properties props = new Properties();
	Session session = Session.getDefaultInstance(props, null);

	try {
	    MimeMessage msg = new MimeMessage(session);
	    msg.setContent(msgBody, "text/html; charset=utf-8");
	    msg.setFrom(new InternetAddress("p@peetahzee.com", "Project Carpoolr"));
	    msg.addRecipient(MimeMessage.RecipientType.TO, new InternetAddress(email, name));
	    msg.setSubject(title);
	    Transport.send(msg);

	} catch (AddressException e) {
	    e.printStackTrace();
	} catch (MessagingException e) {
	    e.printStackTrace();
	} catch (UnsupportedEncodingException e) {
	    e.printStackTrace();
	}
    }
}
