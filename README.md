**Plex to InfluxDB Extended**
------------------------------
A tool for collecting info from your Plex server and sending it to InfluxDB.  This is ideal for displaying Plex specific information in a tool such as Grafana.
*This project forked from the original, awesome [Plex-Data-Collector-For-InfluxDB by barrycarey](https://github.com/barrycarey/Plex-Data-Collector-For-InfluxDB).*

![Screenshot](https://home.prettybaked.com/mediascreenshot/dashboard-plex.png)



#### Dockerized setup with Supervisord

You can build a docker image to run this script with the included Dockerfile or use the Ansible playbook that is part of this Ansible Mediaserver role: [Ansible Role for Plex Media Server, Supporting NZB download services, Webserver + Reverse Proxy, SMB + AFP Fileserver - with support for CephFS and NFS Backends](https://github.com/ajanis/ansible-mediaserver).

Uses [supervisord](http://supervisord.org/) to daemonize the python script.

__If you've deployed your media environment using this role, this container will be started alongside your Plex Media Server.__

#### "Live" Dashboard Example
This hosted dashboard snapshot will allow you view / drill down on sample data for the included dashboard.

*Note: This dashboard makes use of the sysstat, iostat, cpu, netstat and ceph Telegraph plugins.  The plex-specific data at the top is generated specifically from this InfluxDB collector.*

[Plex Media Server, Host and Ceph Data](https://snapshot.raintank.io/dashboard/snapshot/1lK1zf90QwGa4uYz7BW0i3i1wRK3cj87)

![Screenshot](https://home.prettybaked.com/mediascreenshot/dashboard-full.png)


#### Configuration witin config.ini

*Note: If using the Ansible playbook, a config.ini will be generated (from group_vars) on your Docker server and mounted inside your container*

###### General
|Key            |Description                                                                                                         |
|:--------------|:-------------------------------------------------------------------------------------------------------------------|
|Delay          |Delay between updating metrics                                                                                      |
|Output         |Write console output while tool is running                                                                          |
###### InfluxDB
|Key            |Description                                                                                                         |
|:--------------|:-------------------------------------------------------------------------------------------------------------------|
|Address        |IP address or FQDN of influxdb server                                                                               |
|Port           |InfluxDB port to connect to.  8086 in most cases                                                                    |
|Database       |Database to write collected stats to                                                                                |
|Username       |User that has access to the database                                                                                |
|Password       |Password for above user                                                                                             |
###### Plex
|Key            |Description                                                                                                         |
|:--------------|:-------------------------------------------------------------------------------------------------------------------|
|Username       |Plex username                                                                                                       |
|Password       |Plex Password                                                                                                       |
|Servers        |A comma separated list of servers you wish to pull data from.                                                       |
###### Logging
|Key            |Description                                                                                                         |
|:--------------|:-------------------------------------------------------------------------------------------------------------------|
|Enable         |Output logging messages to provided log file                                                                        |
|Level          |Minimum type of message to log.  Valid options are: critical, error, warning, info, debug                           |
|LogFile        |File to log messages to.  Can be relative or absolute path                                                          |
|CensorLogs     |Censor certain things like server names and IP addresses from logs                                                  |


#### Usage

Enter your desired information in config.ini and run plexInfluxdbCollector.py

Optionally, you can specify the --config argument to load the config file from a different location.  

You can build a docker image to run this script with the included Dockerfile (Note: Uses supervisord to daemonize the script) or use the Ansible playbook that is part of this Ansible Mediaserver role: [Ansible Role for Plex Media Server, Supporting NZB download services, Webserver + Reverse Proxy, SMB + AFP Fileserver - with support for CephFS and NFS Backends](https://github.com/ajanis/ansible-mediaserver).

##### Requirements

*Python 3+*

You will need the [*influxdb library*](https://github.com/influxdata/influxdb-python) installed to use this.  This is installed via the following command:

```
pip3 install -r requirements.txt
```

#### InfluxDB Fields
|Field              |Description                                                                                            |
|:------------------|:------------------------------------------------------------------------------------------------------|
|media_type         | Movie, TV Show, Music, or Unknown                                                                     |
|stream_title       | For TV and Music: An aggregation of the grandparent title (series or artist name) and track or episode title. For movies, the movie title|
|grandparent_title  | Blank for movies. Series title for TV shows. Artist title for music                                   |
|parent_title       | Blank for movies. Season title (e.g. Season 1) for TV Shows. Album title for music                    |
|parent_index       | Blank for movies and music. Season number for TV shows                                                |
|title              | Movie, episode, or track title                                                                        |
|year               | Blank for music. Series or Movie year of release                                                      |
|index              | Blank for movies. Episode number for TV Shows. Track number for music.                                |
|container          | File type of the media (e.g. mkv, mp4, mp3, flac, etc.)                                                |
|resolution         | Video resolution (e.g. 4k, 1080p, 720p) for movies and TV. Audio bitrate for music.                   |
|video_codec        | Codec for video stream (e.g. h264, h265, mpeg)                                                        |
|audio_codec        | Codec for audio stream                                                                                |
|transcode_video    | DirectPlay, DirectStream (container remux usually because audio is being transcoded or client doesn't natively support container), or Transcoding|
|transcode_audio    | DirectPlay, DirectStream, or Transcode                                                                        |
|transcode_summary  | Reflects transcoding status of both video and audio (or just audio in the case of music)              |
|video_framerate    | Frame rate for video stream. Blank for music                                                          |
|length_ms          | Length of track, epsidode, or movie in milliseconds                                                   |
|player             | Device name of client playing the media                                                               |
|user               | User name playing the media                                                                           |
|platform           | OS or application playing the media (e.g. Android, Firefox, etc.)                                     |
|start_time         | Time when playback session started OR when first seen by Plex-Data-Collector-Extended (see notes below)|
|duration           | How long the playback session has been active (see notes below)                                       |
|position_ms        | Current playback position in milliseconds                                                             |
|pos_percent        | Current playback position as a percent of length.  Value is between 0 and 1.                          |
|status             | Current session status (playing, paused, buffering)                                                   |


##### Notes:
The start_time and duration fields are manually calculated by the application based on when it first receives data about a session.  It is accurate to within the value used for ***delay*** in the config.ini file.
Since the Plex API doesn't provide retrospective information for streams that are already in-progress, the duration and start_time will be calculated based on when Plex-Data-Collector-Extend is started.

***Grafana and start_time field***
If you are using Grafana to generate a dashboard, the start_time field will appear to have an incorrect date.  To resolve this, use a math operator to multiply the start_time field by 1000.

#### InfluxDB Tags
|Tag                |Description                                                                                            |
|:------------------|:------------------------------------------------------------------------------------------------------|
|host               |Name of Plex server that stream is being played from                                                   |
|player_address     |IP address of client                                                                                   |
|session_id         |Plex internal ID number for playback session                                                           |


#### Version History

|Version            |Description                                                                                            |
|:------------------|:------------------------------------------------------------------------------------------------------|
|v0.1.3.1           | Fixed dumb mistake with processing the year field                                                     |
|v0.1.3             | Fixed issue with TV Shows not being properly written to Now Playing                                   |
|v0.1.2             | Stats for libraries containing TV shows will now be gathered regardless of the actual name of the library. Previously, season and episode stats would only be gathered if the library was specifically named "TV Shows".
|                   |Collecting of library stats will now only be performed every 30 minutes by default. This should lessen impact of extremely large libraries causing delays in now_playing and active_streams stats being updated. Eventually, I'd like to move the library stat collection out to a separate thread.
|                   |Added new LibraryDelay option to config.ini under GENERAL section to allow specifying how long (in seconds) to wait between gathering library stats. If the value is missing from the INI, a default value of 1800 seconds (30 minutes) will be used.
|v0.1.1             | Fixed crash when Plex does not provide a year for an active stream                                    |
|v0.1               | Initial release                                                                                       |
