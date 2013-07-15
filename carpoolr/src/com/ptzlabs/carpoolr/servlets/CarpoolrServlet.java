package com.ptzlabs.carpoolr.servlets;

import static com.googlecode.objectify.ObjectifyService.ofy;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
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

import com.google.appengine.api.datastore.GeoPt;
import com.google.appengine.api.users.User;
import com.google.appengine.api.users.UserService;
import com.google.appengine.api.users.UserServiceFactory;
import com.googlecode.objectify.Key;
import com.ptzlabs.carpoolr.Driver;
import com.ptzlabs.carpoolr.Event;
import com.ptzlabs.carpoolr.Rider;
import com.ptzlabs.carpoolr.Utils;

@SuppressWarnings("serial")
public class CarpoolrServlet extends HttpServlet {

	public void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
		resp.setContentType("text/plain");
		resp.getWriter().println("Hello, world");
	}

	public void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
		UserService userService = UserServiceFactory.getUserService();
		User user = userService.getCurrentUser();

		if (req.getParameter("mode").equals("startEvent")) {

			String code = Utils.md5(new Date().getTime() + "ptzHello").substring(0, 5);
			Date eventArrivalTime = Utils.parseDate("yyyy/MM/dd HH:mm z", req.getParameter("eventArrivalTime"));
			GeoPt destination = new GeoPt(Float.valueOf(req.getParameter("eventDestinationLat")),
					Float.valueOf(req.getParameter("eventDestinationLng")));
			GeoPt origin = new GeoPt(Float.valueOf(req.getParameter("eventOriginLat")),
					Float.valueOf(req.getParameter("eventOriginLng")));
			Event e = new Event(req.getParameter("eventName"), code, user, eventArrivalTime, destination, origin,
					req.getParameter("eventDestinationAddress"), req.getParameter("eventOriginAddress"));
			Key<Event> k = ofy().save().entity(e).now();

			resp.sendRedirect("/event.jsp?id=" + k.getId());

			String msgBody = "<h1>New event at Project Carpoolr</h1>"
					+ "<p>Hi there,</p>"
					+ "<p>Thanks for creating your event <b>"
					+ e.name
					+ "</b> at Project Carpoolr!</p>"
					+ "<p>You may now share this event with your friends and plan a carpool together by copying the link below. Thanks for using Carpoolr!</p>"
					+ "<p><b>" + e.getEventLink() + "</b></p>" + "<p>Project Carpoolr.</p>";

			sendMessage("You have just created a new event at Project Carpoolr", msgBody, user.getEmail(),
					user.getNickname());

		} else if (req.getParameter("mode").equals("addRider")) {

			Key<Event> eventKey = Key.create(Event.class, Long.valueOf(req.getParameter("event")));
			Event event = ofy().load().key(eventKey).get();
			GeoPt location = new GeoPt(Float.valueOf(req.getParameter("riderLocationLat")), Float.valueOf(req
					.getParameter("riderLocationLng")));

			Rider rider = new Rider(eventKey, req.getParameter("riderLocationAddress"), location,
					req.getParameter("riderName"), null, user);
			Key<Rider> k = ofy().save().entity(rider).now();

			String msgBody = "<h1>You signed up for a ride</h1>"
					+ "<p>Hi there, "
					+ rider.name
					+ ",</p>"
					+ "<p>Thanks for signing up for a ride for <b>"
					+ event.name
					+ "</b> at Project Carpoolr!</p>"
					+ "<p>While we're stil trying to get you a ride, share the event with your friends by copying the link below!</p>"
					+ "<p><b>" + event.getEventLink() + "</b></p>"
					+ "<p>Project Carpoolr.</p>";

			sendMessage(event.name + ": Ride registration successful", msgBody, user.getEmail(), user.getNickname());

			resp.sendRedirect("/event.jsp?code=" + event.code + "&nr=" + k.getId());

		} else if (req.getParameter("mode").equals("addDriver")) {

			Key<Event> eventKey = Key.create(Event.class,
					Long.valueOf(req.getParameter("event")));
			Event event = ofy().load().key(eventKey).get();
			GeoPt location = new GeoPt(Float.valueOf(req.getParameter("driverLocationLat")), Float.valueOf(req
					.getParameter("driverLocationLng")));

			Driver driver = new Driver(eventKey, req.getParameter("driverLocationAddress"), Integer.valueOf(req
					.getParameter("driverCapacity")), location, req.getParameter("driverName"), user);
			Key<Driver> k = ofy().save().entity(driver).now();

			String msgBody = "<h1>You signed up to drive</h1>"
					+ "<p>Hi there, "
					+ driver.name
					+ ",</p>"
					+ "<p>Thanks for signing up for to be a driver for <b>"
					+ event.name
					+ "</b> at Project Carpoolr!</p>"
					+ "<p>While we're stil trying to organize rides, share the event with your friends by copying the link below!</p>"
					+ "<p><b>" + event.getEventLink() + "</b></p>"
					+ "<p>Project Carpoolr.</p>";

			sendMessage(event.name + ": Driver registration successful", msgBody, user.getEmail(), user.getNickname());

			resp.sendRedirect("/event.jsp?code=" + event.code + "&nd=" + k.getId());

		} else if (req.getParameter("mode").equals("pairRider")) {
			Rider rider = ofy().load().type(Rider.class).id(Long.valueOf(req.getParameter("rider"))).get();
			Event event = ofy().load().type(Event.class).id(rider.getEvent().id).get();
			Driver driver = ofy().load().type(Driver.class).id(Long.valueOf(req.getParameter("driver"))).get();

			if (driver == null || rider == null || event == null) {
				resp.sendRedirect("/");
				return;
			}

			rider.setDriver(Key.create(Driver.class, driver.id));
			// rider.setProperty("pairedDriver", Integer.valueOf(req.getParameter("driver")));
			ofy().save().entity(rider).now();

			String msgBody = "<h1>You just got a ride!</h1>" + "<p>Hi there, " + rider.name + ",</p>"
					+ "<p>Thanks for your patience! For your event <b>" + event.name
					+ "</b>, we have successfully found you a ride from <b>" + driver.name + "</b>.</p>"
					+ "<p>Enjoy your trip!</p>" + "<p>More details can be found at: "
					+ "<b>" + event.getEventLink() + "</b></p>"
					+ "<p>Project Carpoolr.</p>";
			sendMessage(event.name + ": You just got a ride!", msgBody,
					rider.user.getEmail(), rider.user.getNickname());

			msgBody = "<h1>You just got paired with a rider!</h1>" + "<p>Hi there, "
					+ driver.name + ",</p>"
					+ "<p>Thanks for your patience and signing up to be a dirver for <b>" + event.name
					+ "</b> at Project Carpoolr! We have successfully paired you with rider <b>"
					+ rider.name + "</b>.</p>" + "<p>Enjoy your trip!</p>"
					+ "<p>More details can be found at: <b>" + event.getEventLink() + "</b></p>"
					+ "<p>Project Carpoolr.</p>";
			sendMessage(event.name + ": You just got paired with a rider!", msgBody,
					driver.user.getEmail(), driver.user.getNickname());

			resp.getWriter().println("OK");
		} else {
			resp.sendRedirect("/");
		}
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
