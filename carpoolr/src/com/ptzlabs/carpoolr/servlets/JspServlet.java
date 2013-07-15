package com.ptzlabs.carpoolr.servlets;

import static com.googlecode.objectify.ObjectifyService.ofy;

import java.util.List;

import com.googlecode.objectify.Key;
import com.ptzlabs.carpoolr.Driver;
import com.ptzlabs.carpoolr.Event;
import com.ptzlabs.carpoolr.People;
import com.ptzlabs.carpoolr.Rider;

public abstract class JspServlet {

	public static Event getEvent(long id) {
		return ofy().load().key(Key.create(Event.class, id)).get();
	}

	public static Event getEvent(String code) {
		return ofy().load().type(Event.class).filter("code", code).first().get();
	}

	public static List<Rider> getRiders(long eventID) {
		return ofy().load().type(Rider.class).filter("event", Key.create(Event.class, eventID)).list();
	}

	public static Rider getRider(long riderID) {
		return ofy().load().key(Key.create(Rider.class, riderID)).get();
	}

	public static List<Driver> getDrivers(long eventID) {
		return ofy().load().type(Driver.class).filter("event", Key.create(Event.class, eventID)).list();
	}

	public static Driver getDriver(long driverID) {
		return ofy().load().key(Key.create(Driver.class, driverID)).get();
	}

	public static List<People> getPeople(long eventID) {
		return ofy().load().type(People.class).filter("event", Key.create(Event.class, eventID)).list();
	}

	public static String redirectHomepage() {
		return "<script type=\"text/javascript\">window.location = \"/\";</script>";
	}

}
