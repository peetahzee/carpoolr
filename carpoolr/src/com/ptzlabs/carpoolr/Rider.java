package com.ptzlabs.carpoolr;

import java.util.Date;

import com.google.appengine.api.datastore.GeoPt;
import com.google.appengine.api.users.User;
import com.googlecode.objectify.Key;
import com.googlecode.objectify.annotation.EntitySubclass;

@EntitySubclass(index = true)
public class Rider extends People {

	public Key<Driver> pairedDriver;

	private Rider() {}

	public Rider(Key<Event> event, String address, GeoPt location, String name, Key<Driver> driver, User user) {
		super();
		this.event = event;
		this.address = address;
		this.location = location;
		this.name = name;
		this.pairedDriver = driver;
		this.user = user;

		this.time = new Date();
	}

	public void setDriver(Key<Driver> d) {
		pairedDriver = d;
	}


}
