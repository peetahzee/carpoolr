package com.ptzlabs.carpoolr;

import com.google.gson.annotations.Expose;
import com.googlecode.objectify.annotation.Entity;
import com.googlecode.objectify.annotation.Id;
import com.googlecode.objectify.annotation.Index;

@Entity
public class User extends Jsonifiable {
	@Id
	public Long id;

	@Expose
	@Index
	public String name;
	@Expose
	public String email;
	@Expose
	@Index
	public String googleUserId;
	@Expose
	public String googleDisplayName;
	@Expose
	public String googlePublicProfileUrl;
	@Expose
	public String googlePublicProfilePhotoUrl;
	@Expose
	public String googleAccessToken;
	@Expose
	public String googleRefreshToken;

	public Long googleExpiresAt;
	public Long googleExpiresIn;

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getEmail() {
		return email;
	}

	public void setEmail(String email) {
		this.email = email;
	}

	public String getGoogleUserId() {
		return googleUserId;
	}

	public void setGoogleUserId(String googleUserId) {
		this.googleUserId = googleUserId;
	}

	public String getGoogleDisplayName() {
		return googleDisplayName;
	}

	public void setGoogleDisplayName(String googleDisplayName) {
		this.googleDisplayName = googleDisplayName;
	}

	public String getGooglePublicProfileUrl() {
		return googlePublicProfileUrl;
	}

	public void setGooglePublicProfileUrl(String googlePublicProfileUrl) {
		this.googlePublicProfileUrl = googlePublicProfileUrl;
	}

	public String getGooglePublicProfilePhotoUrl() {
		return googlePublicProfilePhotoUrl;
	}

	public void setGooglePublicProfilePhotoUrl(String googlePublicProfilePhotoUrl) {
		this.googlePublicProfilePhotoUrl = googlePublicProfilePhotoUrl;
	}

	public String getGoogleAccessToken() {
		return googleAccessToken;
	}

	public void setGoogleAccessToken(String googleAccessToken) {
		this.googleAccessToken = googleAccessToken;
	}

	public String getGoogleRefreshToken() {
		return googleRefreshToken;
	}

	public void setGoogleRefreshToken(String googleRefreshToken) {
		this.googleRefreshToken = googleRefreshToken;
	}

	public Long getGoogleExpiresAt() {
		return googleExpiresAt;
	}

	public void setGoogleExpiresAt(Long googleExpiresAt) {
		this.googleExpiresAt = googleExpiresAt;
	}

	public Long getGoogleExpiresIn() {
		return googleExpiresIn;
	}

	public void setGoogleExpiresIn(Long googleExpiresIn) {
		this.googleExpiresIn = googleExpiresIn;
	}

}
