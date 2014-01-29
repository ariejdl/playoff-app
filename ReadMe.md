## Playoff App

### blurb


little project taking about 3 months of my spare time (April-July), first iphone app, video mixing/mashup, allows people to publish and then look at the underlying clips of a video and add to them, including scraping logic for a couple of websites, uses the apple APIs for capture + audio/video splicing/manipulation, quite interesting to work with.

uses stackmob as 'back-end as a service' for simplicity, was painful having to move from Parse to Stackmob after a month, also knocked together a simple website <http://www.getplayoff.com> which allows viewing clips and 'playoffs' a collection of rebounded clips...
- clip: <http://www.getplayoff.com/#!/view/41D251CF-1D8A-4D61-9401-FB58D35C09C8>
- thread: <http://www.getplayoff.com/#!thread/7AC50CDE-4472-4178-9DEB-3107B8D47FE8>

Builds on iOS6, doesn't seem to build anymore on XCode 5 + iOS7, but the extant app in app store does run on iOS7 untouched at time of writing.
<https://itunes.apple.com/us/app/playoff/id650635035?ls=1&mt=8>

all design my own...

**Why I did this**: wanted a shot at an iPhone app, wanted to do something fun (see the videos...), wanted to learn about modern marketing/sales/promotion.

### more blurb

- customising and high design standards slowed development down, aware that iOS7 was coming out I bent the iOS6 UI look to my wishes, things like custom UIToolbars etc... PlyTheme.h/m

- standard social stuff implemented, twitter + facebook intgtn./ogin, commenting system, following, liking, user profiles + images...

- The interesting places you may want to look in the playoff/playoff folder are:

- PLYVideoComposer.m - audio and video composition logic, taking tracks and turning them into one combined video

- PLYAppDelegate.m - plopped a lot of stuff here, including the track video upload code, with more time would have refactored

- PLYVideoMixerCell.m - logic for the sliders, just a modified UITableViewCell

- uses amazon S3 for saving videos and 'clips' that make them up.

----

Git history not given for all the various credentials.