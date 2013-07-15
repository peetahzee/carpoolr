package com.ptzlabs.carpoolr;

import java.util.Date;

import com.google.appengine.api.datastore.GeoPt;
import com.google.appengine.api.users.User;
import com.googlecode.objectify.Key;
import com.googlecode.objectify.annotation.EntitySubclass;

@EntitySubclass(index = true)
public class Driver extends People {
	
	public int capacity;
	
	private Driver() {}

	public Driver(Key<Event> event, String address, int capacity, GeoPt location, String name, User user) {
		super();
		this.event = event;
		this.address = address;
		this.capacity = capacity;
		this.location = location;
		this.name = name;
		this.user = user;

		this.time = new Date();
	}

}
