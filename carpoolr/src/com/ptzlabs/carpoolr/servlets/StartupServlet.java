package com.ptzlabs.carpoolr.servlets;

import javax.servlet.http.HttpServlet;

import com.googlecode.objectify.ObjectifyService;
import com.ptzlabs.carpoolr.Driver;
import com.ptzlabs.carpoolr.Rider;
import com.ptzlabs.carpoolr.User;

/**
 * Used to register entities with objectify.
 */
public class StartupServlet extends HttpServlet {
	static {
		ObjectifyService.register(User.class);
		ObjectifyService.register(Driver.class);
		ObjectifyService.register(Rider.class);
	}
}
