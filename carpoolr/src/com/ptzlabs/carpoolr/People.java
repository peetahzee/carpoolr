package com.ptzlabs.carpoolr;

import static com.googlecode.objectify.ObjectifyService.ofy;

import java.util.Date;

import com.google.appengine.api.datastore.GeoPt;
import com.google.appengine.api.users.User;
import com.googlecode.objectify.Key;
import com.googlecode.objectify.annotation.Entity;
import com.googlecode.objectify.annotation.Id;
import com.googlecode.objectify.annotation.Ignore;
import com.googlecode.objectify.annotation.Parent;

@Entity
public abstract class People {
	@Id
	public long id;
	@Parent
	protected Key<Event> event;

	public String address;
	public GeoPt location;
	public String name;

	public Date time;
	public User user;

	@Ignore
	Event e;

	public Event getEvent() {
		if (e == null) {
			e = ofy().load().key(event).get();
		}

		return e;
	}

	public String getAvatar() {
		return "<img alt=\"" + name + "\" title=\"" + name + "\" class=\"rider_avatar\" " +
				"data-riderid=\"" + id + "\" " + "src=\"" + getAvatarSrc() + "\" />";
	}

	public String getAvatarSrc() {
		return "http://www.gravatar.com/avatar/" + Utils.md5(user.getEmail().toLowerCase()) + "?d=identicon";
	}
}
