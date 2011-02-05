/* TrackViewController.m - Display a track
 * 
 * Copyright 2011 Last.fm Ltd.
 *   - Primarily authored by Sam Steele <sam@last.fm>
 *
 * This file is part of MobileLastFM.
 *
 * MobileLastFM is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * MobileLastFM is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with MobileLastFM.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "TrackViewController.h"
#import "UIViewController+NowPlayingButton.h"
#import "UITableViewCell+ProgressIndicator.h"
#import "MobileLastFMApplicationDelegate.h"
#include "version.h"
#import "NSString+URLEscaped.h"
#import "ArtworkCell.h"
#import "MobileLastFMApplicationDelegate.h"
#import "UIApplication+openURLWithWarning.h"
#import "UIColor+LastFMColors.h"

@implementation TrackViewController
- (id)initWithTrack:(NSString *)track byArtist:(NSString *)artist {
	if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		_artist = [artist retain];
		_track = [track retain];
		_metadata = [[[LastFMService sharedInstance] metadataForTrack:track byArtist:artist inLanguage:@"en"] retain];
		_tags = [[[LastFMService sharedInstance] topTagsForTrack:track byArtist:artist] retain];
		_shouts = [[[LastFMService sharedInstance] shoutsForTrack:track byArtist:artist] retain];
		_loved = NO;
		_addedToLibrary = NO;
		self.title = track;
	}
	return self;
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self showNowPlayingButton:[(MobileLastFMApplicationDelegate *)[UIApplication sharedApplication].delegate isPlaying]];
	[self rebuildMenu];
}
- (void)viewDidLoad {
	//self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
	//self.tableView.sectionHeaderHeight = 0;
	//self.tableView.sectionFooterHeight = 0;
	self.tableView.backgroundColor = [UIColor lfmTableBackgroundColor];
	self.tableView.scrollsToTop = NO;
	_bioView = [[TTStyledTextLabel alloc] initWithFrame:CGRectZero];
	
	_toggle = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Info", @"Related Tags", @"Shouts", nil]];
	_toggle.segmentedControlStyle = UISegmentedControlStyleBar;
	_toggle.selectedSegmentIndex = 0;
	_toggle.frame = CGRectMake(6,6,self.view.frame.size.width - 12, _toggle.frame.size.height);
	[_toggle addTarget:self
							action:@selector(rebuildMenu)
		forControlEvents:UIControlEventValueChanged];
	
	UINavigationBar *toggleContainer = [[UINavigationBar alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,_toggle.frame.size.height + 12)];
	//if(_paintItBlack)
	//	toggleContainer.barStyle = UIBarStyleBlackOpaque;
	[toggleContainer addSubview: _toggle];
	self.tableView.tableHeaderView = toggleContainer;
	[toggleContainer release];
	
}
- (void)rebuildMenu {
	NSString *bio = [[_metadata objectForKey:@"wiki"] stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
	NSString *html = [NSString stringWithFormat:@"%@ <a href=\"http://www.last.fm/music/%@/_/%@/+wiki\">Read More »</a>", bio, [_artist URLEscaped], [_track URLEscaped]];
	_bioView.html = html;
	
	if(_data)
		[_data release];
	
	NSMutableArray *sections = [[NSMutableArray alloc] init];
	NSMutableArray *stations;
	
	if(_toggle.selectedSegmentIndex == 0) {
		[sections addObject:@"heading"];
		
		if([[[NSUserDefaults standardUserDefaults] objectForKey:@"lastfm_subscriber"] intValue])
			[sections addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"",
																														 [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSString stringWithFormat:@"Play %@ Radio", _artist], [NSString stringWithFormat:@"lastfm://artist/%@/similarartists", [_artist URLEscaped]], nil]
																																																									 forKeys:[NSArray arrayWithObjects:@"title", @"url", nil]], nil]
																														 , nil] forKeys:[NSArray arrayWithObjects:@"title",@"stations",nil]]];

		if([[_metadata objectForKey:@"wiki"] length])
			[sections addObject:@"bio"];

		NSString *ITMSURL = [NSString stringWithFormat:@"http://phobos.apple.com/WebObjects/MZSearch.woa/wa/search?term=%@ %@&s=143444&partnerId=2003&affToken=www.last.fm", 
												 _artist,
												 _track];
		NSString *URL;
		if([[[NSUserDefaults standardUserDefaults] objectForKey:@"country"] isEqualToString:@"United States"])
			URL = [NSString stringWithFormat:@"http://click.linksynergy.com/fs-bin/stat?id=bKEBG4*hrDs&offerid=78941&type=3&subid=0&tmpid=1826&RD_PARM1=%@", [[ITMSURL URLEscaped] stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"]];
		else
			URL = [NSString stringWithFormat:@"http://clk.tradedoubler.com/click?p=23761&a=1474288&url=%@&tduid=lastfm&partnerId=2003", [[ITMSURL URLEscaped] stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"]];
		[sections addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"",
																														 [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Buy on iTunes", URL, nil]
																																																									 forKeys:[NSArray arrayWithObjects:@"title", @"url", nil]],
																															[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Love Track", @"love://", nil]
																																													forKeys:[NSArray arrayWithObjects:@"title", @"url", nil]],
																															[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Add To Library", @"library://", nil]
																																													forKeys:[NSArray arrayWithObjects:@"title", @"url", nil]],
																															[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Tag Track", @"tag://", nil]
																																													forKeys:[NSArray arrayWithObjects:@"title", @"url", nil]],
																															[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Share Track", @"share://", nil]
																																																									 forKeys:[NSArray arrayWithObjects:@"title", @"url", nil]], nil]
																														 , nil] forKeys:[NSArray arrayWithObjects:@"title",@"stations",nil]]];
	} else if(_toggle.selectedSegmentIndex == 1) {	
		if([_tags count]) {
			stations = [[NSMutableArray alloc] init];
			for(int x=0; x<[_tags count] && x < 10; x++) {
				[stations addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[[_tags objectAtIndex:x] objectForKey:@"name"],
																																 [NSString stringWithFormat:@"lastfm-tag://%@", [[[_tags objectAtIndex:x] objectForKey:@"name"] URLEscaped]],nil] forKeys:[NSArray arrayWithObjects:@"title", @"url",nil]]];
			}
			[sections addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"", stations, nil] forKeys:[NSArray arrayWithObjects:@"title",@"stations",nil]]];
			[stations release];
		}
	} else if(_toggle.selectedSegmentIndex == 2) {	
		if([_shouts count]) {
			stations = [[NSMutableArray alloc] init];
			for(int x=0; x<[_shouts count] && x < 10; x++) {
				[stations addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[[_shouts objectAtIndex:x] objectForKey:@"author"], [[_shouts objectAtIndex:x] objectForKey:@"body"],
																																 @"",nil] forKeys:[NSArray arrayWithObjects:@"title", @"artist", @"url",nil]]];
			}
			[sections addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"", stations, nil] forKeys:[NSArray arrayWithObjects:@"title",@"stations",nil]]];
			[stations release];
		}
	}
	_data = sections;
	
	[self.tableView reloadData];
	[self loadContentForCells:[self.tableView visibleCells]];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [_data count];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if([[_data objectAtIndex:section] isKindOfClass:[NSDictionary class]])
		return [[[_data objectAtIndex:section] objectForKey:@"stations"] count];
	else
		return 1;
}
/*- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
 if([self tableView:tableView numberOfRowsInSection:section] > 1)
 return 10;
 else
 return 0;
 }*/
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if([[_data objectAtIndex:section] isKindOfClass:[NSDictionary class]]) {
		return [((NSDictionary *)[_data objectAtIndex:section]) objectForKey:@"title"];
	}	else if([[_data objectAtIndex:section] isKindOfClass:[NSString class]] && [[_data objectAtIndex:section] isEqualToString:@"bio"]) {
		return @"About This Track";
	} else {
		return nil;
	}
}
/*- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
 return [[[UIView alloc] init] autorelease];
 }*/
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if([indexPath section] == 0 && _toggle.selectedSegmentIndex == 0)
		return 112;
	else if(_toggle.selectedSegmentIndex == 0 && [[_data objectAtIndex:[indexPath section]] isKindOfClass:[NSString class]] && [[_data objectAtIndex:[indexPath section]] isEqualToString:@"bio"]) {
		_bioView.text.width = self.view.frame.size.width - 32;
		return _bioView.text.height + 16;
	} else if(_toggle.selectedSegmentIndex == 2) {
		ArtworkCell *cell = (ArtworkCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
		return [cell.subtitle.text sizeWithFont:cell.subtitle.font constrainedToSize:CGSizeMake(self.tableView.frame.size.width - 38, MAXFLOAT) lineBreakMode:cell.subtitle.lineBreakMode].height + 36;
	}
	else
		return 52;
}
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self becomeFirstResponder];
	[self dismissModalViewControllerAnimated:YES];
}
- (void)shareToAddressBook {
	if(NSClassFromString(@"MFMailComposeViewController") != nil && [MFMailComposeViewController canSendMail]) {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
		MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
		[mail setMailComposeDelegate:self];
		[mail setSubject:[NSString stringWithFormat:@"Last.fm: %@ shared %@",[[NSUserDefaults standardUserDefaults] objectForKey:@"lastfm_user"], _track]];
		[mail setMessageBody:[NSString stringWithFormat:@"Hi there,<br/>\
													<br/>\
													%@ at Last.fm wants to share this with you:<br/>\
													<br/>\
													<a href='http://www.last.fm/music/%@/_/%@'>%@</a><br/>\
													<br/>\
													If you like this, add it to your Library. <br/>\
													This will make it easier to find, and will tell your Last.fm profile a bit more<br/>\
													about your music taste. This improves your recommendations and your Last.fm Radio.<br/>\
													<br/>\
													The more good music you add to your Last.fm Profile, the better it becomes :)<br/>\
													<br/>\
													Best Regards,<br/>\
													The Last.fm Team<br/>\
													--<br/>\
													Visit Last.fm for personal radio, tons of recommended music, and free downloads.<br/>\
													Create your own music profile at <a href='http://www.last.fm'>Last.fm</a><br/>",
													[[NSUserDefaults standardUserDefaults] objectForKey:@"lastfm_user"],
													[_artist URLEscaped],
													[_track URLEscaped],
													_track
													] isHTML:YES];
		[self presentModalViewController:mail animated:YES];
		[mail release];
	} else {
		ABPeoplePickerNavigationController *peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
		peoplePicker.displayedProperties = [NSArray arrayWithObjects:[NSNumber numberWithInteger:kABPersonEmailProperty], nil];
		peoplePicker.peoplePickerDelegate = self;
		[self.navigationController presentModalViewController:peoplePicker animated:YES];
		[peoplePicker release];
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
	}
}
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
	return YES;
}
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
	ABMultiValueRef value = ABRecordCopyValue(person, property);
	NSString *email = (NSString *)ABMultiValueCopyValueAtIndex(value, ABMultiValueGetIndexForIdentifier(value, identifier));
	[self.navigationController dismissModalViewControllerAnimated:YES];
	
	[[LastFMService sharedInstance] recommendTrack:_track
																				byArtist:_artist
																	toEmailAddress:email];
	[email release];
	CFRelease(value);
	
	if([LastFMService sharedInstance].error)
		[((MobileLastFMApplicationDelegate *)[UIApplication sharedApplication].delegate) reportError:[LastFMService sharedInstance].error];
	else
		[((MobileLastFMApplicationDelegate *)[UIApplication sharedApplication].delegate) displayError:NSLocalizedString(@"SHARE_SUCCESSFUL", @"Share successful") withTitle:NSLocalizedString(@"SHARE_SUCCESSFUL_TITLE", @"Share successful title")];
	return NO;
}
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
	[self.navigationController dismissModalViewControllerAnimated:YES];
}
- (void)shareToFriend {
	FriendsViewController *friends = [[FriendsViewController alloc] initWithUsername:[[NSUserDefaults standardUserDefaults] objectForKey:@"lastfm_user"]];
	if(friends) {
		friends.delegate = self;
		friends.title = NSLocalizedString(@"Choose A Friend", @"Friend selector title");
		UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:friends];
		[friends release];
		[self.navigationController presentModalViewController:nav animated:YES];
		[nav release];
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
	}
}
- (void)friendsViewController:(FriendsViewController *)friends didSelectFriend:(NSString *)username {
	[[LastFMService sharedInstance] recommendTrack:_track
																				byArtist:_artist
																	toEmailAddress:username];
	if([LastFMService sharedInstance].error)
		[((MobileLastFMApplicationDelegate *)[UIApplication sharedApplication].delegate) reportError:[LastFMService sharedInstance].error];
	else
		[((MobileLastFMApplicationDelegate *)[UIApplication sharedApplication].delegate) displayError:NSLocalizedString(@"SHARE_SUCCESSFUL", @"Share successful") withTitle:NSLocalizedString(@"SHARE_SUCCESSFUL_TITLE", @"Share successful title")];
	
	[self.navigationController dismissModalViewControllerAnimated:YES];
}
- (void)friendsViewControllerDidCancel:(FriendsViewController *)friends {
	[self.navigationController dismissModalViewControllerAnimated:YES];
}
-(void)tagEditorDidCancel {
	[self dismissModalViewControllerAnimated:YES];
}
- (void)tagEditorAddTags:(NSArray *)tags {
	[[LastFMService sharedInstance] addTags:tags toTrack:_track byArtist:_artist];
	if([LastFMService sharedInstance].error)
		[((MobileLastFMApplicationDelegate *)[UIApplication sharedApplication].delegate) reportError:[LastFMService sharedInstance].error];
	[self dismissModalViewControllerAnimated:YES];
}
- (void)tagEditorRemoveTags:(NSArray *)tags {
	for(NSString *tag in tags) {
		[[LastFMService sharedInstance] removeTag:tag fromTrack:_track byArtist:_artist];
		if([LastFMService sharedInstance].error)
			[((MobileLastFMApplicationDelegate *)[UIApplication sharedApplication].delegate) reportError:[LastFMService sharedInstance].error];
	}
}
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Contacts", @"Share to Address Book")] ||
		 [[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"E-mail Address"]) {
		[self shareToAddressBook];
	} else if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Last.fm Friends", @"Share to Last.fm friend")]) {
		[self shareToFriend];
	}
}
-(void)_rowSelected:(NSIndexPath *)indexPath {
	if([indexPath section] == 0 && _toggle.selectedSegmentIndex == 0) {
		[[UIApplication sharedApplication] openURLWithWarning:[NSURL URLWithString:[NSString stringWithFormat:@"lastfm-album://%@/%@", [_artist URLEscaped], [[_metadata objectForKey:@"album"] URLEscaped]]]];
	}
	if([[_data objectAtIndex:[indexPath section]] isKindOfClass:[NSDictionary class]]) {
		NSString *station = [[[[_data objectAtIndex:[indexPath section]] objectForKey:@"stations"] objectAtIndex:[indexPath row]] objectForKey:@"url"];
		NSLog(@"Station: %@", station);
		if([station isEqualToString:@"love://"]) {
			[[LastFMService sharedInstance] loveTrack:_track byArtist:_artist];
			if([LastFMService sharedInstance].error) {
				[((MobileLastFMApplicationDelegate *)([UIApplication sharedApplication].delegate)) reportError:[LastFMService sharedInstance].error];
			} else {
				_loved = YES;
			}
		} else if([station isEqualToString:@"library://"]) {
			[[LastFMService sharedInstance] addTrackToLibrary:_track byArtist:_artist];
			if([LastFMService sharedInstance].error) {
				[((MobileLastFMApplicationDelegate *)([UIApplication sharedApplication].delegate)) reportError:[LastFMService sharedInstance].error];
			} else {
				_addedToLibrary = YES;
			}
		} else if([station isEqualToString:@"tag://"]) {
			NSArray *topTags = [[[LastFMService sharedInstance] topTagsForTrack:_track byArtist:_artist] sortedArrayUsingFunction:tagSort context:nil];
			NSArray *userTags = [[[LastFMService sharedInstance] tagsForUser:[[NSUserDefaults standardUserDefaults] objectForKey:@"lastfm_user"]] sortedArrayUsingFunction:tagSort context:nil];
			TagEditorViewController *t = [[TagEditorViewController alloc] initWithTopTags:topTags userTags:userTags];
			t.delegate = self;
			[self presentModalViewController:t animated:YES];
			[t setTags: [[LastFMService sharedInstance] tagsForTrack:_track byArtist:_artist]];
			[t release];
		} else if([station isEqualToString:@"share://"]) {
			UIActionSheet *sheet;
			if(NSClassFromString(@"MFMailComposeViewController") != nil && [NSClassFromString(@"MFMailComposeViewController") canSendMail]) {
				sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Who would you like to share this track with?", @"Share sheet title")
																						delegate:self
																	 cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
															destructiveButtonTitle:nil
																	 otherButtonTitles:@"E-mail Address", NSLocalizedString(@"Last.fm Friends", @"Share to Last.fm friend"), nil];
			} else {
				sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Who would you like to share this track with?", @"Share sheet title")
																						delegate:self
																	 cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
															destructiveButtonTitle:nil
																	 otherButtonTitles:NSLocalizedString(@"Contacts", @"Share to Address Book"), NSLocalizedString(@"Last.fm Friends", @"Share to Last.fm friend"), nil];
			}
			[sheet showInView:self.view];
			[sheet release];
		} else {
			[[UIApplication sharedApplication] openURLWithWarning:[NSURL URLWithString:station]];
		}
	}
	[self.tableView reloadData];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath {
	[tableView deselectRowAtIndexPath:newIndexPath animated:NO];
	if(_toggle.selectedSegmentIndex == 2)
		return;
	[[tableView cellForRowAtIndexPath: newIndexPath] showProgress:YES];
	[self performSelector:@selector(_rowSelected:) withObject:newIndexPath afterDelay:0.1];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *loadingCell = [tableView dequeueReusableCellWithIdentifier:@"LoadingCell"];
	if(!loadingCell) {
		loadingCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LoadingCell"] autorelease];
		loadingCell.textLabel.text = @"Loading";
	}
	ArtworkCell *cell = nil;
	
	if([[_data objectAtIndex:[indexPath section]] isKindOfClass:[NSDictionary class]]) {
		NSArray *stations = [[_data objectAtIndex:[indexPath section]] objectForKey:@"stations"];
		cell = (ArtworkCell *)[tableView dequeueReusableCellWithIdentifier:[[stations objectAtIndex:[indexPath row]] objectForKey:@"title"]];
		if (cell == nil) {
			cell = [[[ArtworkCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[[stations objectAtIndex:[indexPath row]] objectForKey:@"title"]] autorelease];
		}
	}
	if(cell == nil)
		cell = [[[ArtworkCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ArtworkCell"] autorelease];
	
	[cell showProgress: NO];
	cell.accessoryType = UITableViewCellAccessoryNone;
	
	if([indexPath section] == 1 && _toggle.selectedSegmentIndex == 0 && [[[NSUserDefaults standardUserDefaults] objectForKey:@"lastfm_subscriber"] intValue]) {
		UITableViewCell *stationCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"StationCell"] autorelease];
		NSArray *stations = [[_data objectAtIndex:[indexPath section]] objectForKey:@"stations"];
		stationCell.textLabel.text = [[stations objectAtIndex:[indexPath row]] objectForKey:@"title"];
		stationCell.imageView.image = [UIImage imageNamed:@"radiostarter.png"];
		return stationCell;
	}
	
	if([indexPath section] == 0 && _toggle.selectedSegmentIndex == 0) {
		ArtworkCell *profilecell = (ArtworkCell *)[tableView dequeueReusableCellWithIdentifier:@"ProfileCell"];
		if(profilecell == nil) {
			profilecell = [[[ArtworkCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ProfileCell"] autorelease];
			profilecell.selectionStyle = UITableViewCellSelectionStyleNone;
			profilecell.placeholder = @"noimage_album.png";
			profilecell.imageURL = [_metadata objectForKey:@"image"];
			profilecell.shouldCacheArtwork = YES;
			//profilecell.backgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
			//profilecell.backgroundColor = [UIColor clearColor];
			profilecell.title.text = _artist;
			[profilecell addBorder];

			NSString *duration = @"";
			int seconds = [[_metadata objectForKey:@"duration"] floatValue] / 1000.0f;
			if(seconds <= 0) {
				duration = @"00:00";
			} else {
				int h = seconds / 3600;
				int m = (seconds%3600) / 60;
				int s = seconds%60;
				if(h)
					duration = [NSString stringWithFormat:@"%02i:%02i:%02i", h, m, s];
				else
					duration = [NSString stringWithFormat:@"%02i:%02i", m, s];
			}
			
			NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
			[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
			NSString *plays = [NSString stringWithFormat:@"%@ plays in your library",[numberFormatter stringFromNumber:[NSNumber numberWithInteger:[[_metadata objectForKey:@"userplaycount"] intValue]]]];
			profilecell.subtitle.lineBreakMode = UILineBreakModeWordWrap;
			profilecell.subtitle.numberOfLines = 0;
			profilecell.subtitle.text = [NSString stringWithFormat:@"%@\n(%@)\n\n%@", _track, duration, plays];
			[numberFormatter release];
		}
		[profilecell showProgress: NO];
		profilecell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		return profilecell;
	}
	
	if([[_data objectAtIndex:[indexPath section]] isKindOfClass:[NSDictionary class]]) {
		NSArray *stations = [[_data objectAtIndex:[indexPath section]] objectForKey:@"stations"];
		cell.title.text = [[stations objectAtIndex:[indexPath row]] objectForKey:@"title"];
		if([[stations objectAtIndex:[indexPath row]] objectForKey:@"artist"]) {
			cell.subtitle.text = [[stations objectAtIndex:[indexPath row]] objectForKey:@"artist"];
			cell.subtitle.lineBreakMode = UILineBreakModeWordWrap;
			cell.subtitle.numberOfLines = 0;
		}
		cell.shouldCacheArtwork = YES;
		if([[[stations objectAtIndex:[indexPath row]] objectForKey:@"image"] length]) {
			cell.imageURL = [[stations objectAtIndex:[indexPath row]] objectForKey:@"image"];
		} else {
			[cell hideArtwork:YES];
		}
		cell.shouldFillHeight = YES;
		if([indexPath row] == 0)
			cell.shouldRoundTop = YES;
		else
			cell.shouldRoundTop = NO;
		if([indexPath row] == [self tableView:tableView numberOfRowsInSection:[indexPath section]]-1)
			cell.shouldRoundBottom = YES;
		else
			cell.shouldRoundBottom = NO;
	} else if([[_data objectAtIndex:[indexPath section]] isKindOfClass:[NSString class]] && [[_data objectAtIndex:[indexPath section]] isEqualToString:@"bio"]) {
		UITableViewCell *biocell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"BioCell"];
		if(biocell == nil) {
			biocell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"BioCell"] autorelease];
			biocell.selectionStyle = UITableViewCellSelectionStyleNone;
			_bioView.frame = CGRectMake(8,8,self.view.frame.size.width - 32, _bioView.text.height);
			_bioView.backgroundColor = [UIColor clearColor];
			_bioView.textColor = [UIColor blackColor];
			[biocell.contentView addSubview:_bioView];
		}
		return biocell;
	}
	if(_toggle.selectedSegmentIndex == 2) {
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	if(cell.accessoryType == UITableViewCellAccessoryNone && _toggle.selectedSegmentIndex == 1) {
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	if(_toggle.selectedSegmentIndex == 0 && [indexPath section] == 3 && [indexPath row] == 1 && _loved)
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	if(_toggle.selectedSegmentIndex == 0 && [indexPath section] == 3 && [indexPath row] == 2 && _addedToLibrary)
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	return cell;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
- (void)dealloc {
	[super dealloc];
	[_shouts release];
	[_toggle release];
	[_tags release];
	[_artist release];
	[_track release];
	[_metadata release];
	[_bioView release];
	[_data release];
}
@end
