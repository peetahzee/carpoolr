package com.ptzlabs.carpoolr;
import java.util.Date;

import com.google.appengine.api.datastore.GeoPt;
import com.google.appengine.api.users.User;
import com.googlecode.objectify.annotation.Entity;
import com.googlecode.objectify.annotation.Id;
import com.googlecode.objectify.annotation.Index;

@Entity
public class Event {
	@Id
	public long id;
	public String name;
	@Index
	public String code;
	public Date time;
	public User user;

	public Date arrivalTime;
	public GeoPt destination;
	public GeoPt origin;
	public String destinationAddress;
	public String originAddress;

	public Event(String name, String code, User user, Date arrivalTime, GeoPt destination, GeoPt origin,
			String destinationAddress, String originAddress) {
		this.name = name;
		this.code = code;
		this.user = user;
		this.arrivalTime = arrivalTime;
		this.destination = destination;
		this.origin = origin;
		this.destinationAddress = destinationAddress;
		this.originAddress = originAddress;

		this.time = new Date();
	}

	public String getEventLink() {
		return Config.ROOT_ADDRESS + "event.jsp?code=" + code;
	}

}
