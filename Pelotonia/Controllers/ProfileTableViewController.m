//
//  ProfileTableViewController.m
//  Pelotonia
//
//  Created by Mark Harris on 9/5/12.
//
//

#import "ProfileTableViewController.h"
#import "AppDelegate.h"
#import "RiderDataController.h"
#import "SHKActivityIndicator.h"
#import "Pelotonia-Colors.h"
#import "UIImage+Resize.h"
#import "UIImage+RoundedCorner.h"
#import "SHK.h"
#import "SHKFacebook.h"
#import "SHKTwitter.h"
#import "SendPledgeModalViewController.h"

static NSDictionary *sharersTable = nil;


@interface ProfileTableViewController ()

@end

@implementation ProfileTableViewController 
@synthesize donationProgress;
@synthesize storyTextView;
@synthesize followButton;
@synthesize nameAndRouteCell;
@synthesize raisedAmountCell;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (sharersTable == nil) {
        // list of potential sharers that we care about 
        sharersTable = @{@"Twitter" : @"shareOnTwitter",
                         @"Facebook" : @"shareOnFacebook"
                         };
    }

    pull = [[PullToRefreshView alloc] initWithScrollView:(UIScrollView *) self.tableView];
    [pull setDelegate:self];
    [self.tableView addSubview:pull];
}

- (void)viewDidUnload
{
    [self setDonationProgress:nil];
    [self setStoryTextView:nil];
    [self setFollowButton:nil];
    [self setNameAndRouteCell:nil];
    [self setRaisedAmountCell:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self configureView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc
{
    [self.tableView removeObserver:pull forKeyPath:@"contentOffset"];
}

//implementation


- (void)setRider:(Rider *)rider
{
    _rider = rider;
}

#pragma mark - Segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self performSelector:NSSelectorFromString(segue.identifier) withObject:segue.destinationViewController];
}

- (void)showPledge:(SendPledgeModalViewController *)pledgeViewController
{
    pledgeViewController.rider = self.rider;
    pledgeViewController.delegate = self;
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    if (indexPath.section == 0) {
        if (indexPath.row == 3) {
            // show the "share on..." dialog
            [self showShareActionSheet];
        }
    }
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 3, tableView.bounds.size.width - 10, 18)];
    label.textColor = PRIMARY_GREEN;
    label.font = PELOTONIA_FONT(21);
    label.backgroundColor = [UIColor clearColor];
    label.shadowColor = [UIColor blackColor];
    
    if (section == 1)
    {
        label.text = @"My Story";
    }
    [headerView addSubview:label];
    return headerView;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row == 2) {
            // progress row -- hide if we're a volunteer rider
            if ([self.rider.riderType isEqualToString:@"Virtual Rider"] ||
                [self.rider.riderType isEqualToString:@"Volunteer"])
            {
                return 0;
            }
        }
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark -- view configuration

- (void)refreshRider
{
    [self.rider refreshFromWebOnComplete:^(Rider *updatedRider) {
        [self configureView];
        [pull finishedLoading];
    }
    onFailure:^(NSString *error) {
        NSLog(@"Unable to get profile for rider. Error: %@", error);
        [[SHKActivityIndicator currentIndicator] displayCompleted:@"Error"];
        [self configureView];
        [pull finishedLoading];
    }];
}


- (BOOL)following
{
    // return true if current rider is in the dataController
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    RiderDataController *dataController = appDelegate.riderDataController;
    
    return [dataController containsRider:self.rider];
}

- (void)configureView
{
    // set the name & ID appropriately
    self.nameAndRouteCell.textLabel.text = self.rider.name;
    if ([self.rider.riderType isEqualToString:@"Virtual Rider"] ||
        [self.rider.riderType isEqualToString:@"Volunteer"] ||
        [self.rider.riderType isEqualToString:@"Super Peloton"] ||
        [self.rider.riderType isEqualToString:@"Peloton"]) {
        self.nameAndRouteCell.detailTextLabel.text = [NSString stringWithFormat:@"%@", self.rider.riderType];
        self.raisedAmountCell.detailTextLabel.text = [NSString stringWithFormat:@"%@", self.rider.totalRaised];
        self.donationProgress.hidden = YES;
    }
    else
    {
        // Riders and Pelotons are the only ones who get progress
        self.nameAndRouteCell.detailTextLabel.text = [NSString stringWithFormat:@"%@", self.rider.route];
        self.raisedAmountCell.detailTextLabel.text = [NSString stringWithFormat:@"%@ of %@", self.rider.totalRaised, self.rider.totalCommit];
        self.donationProgress.progress = [self.rider.pctRaised floatValue]/100.0;
    }
    self.storyTextView.text = [NSString stringWithFormat:@"%@", self.rider.story];
    
    self.nameAndRouteCell.textLabel.font = PELOTONIA_FONT(21);
    self.nameAndRouteCell.detailTextLabel.font = PELOTONIA_SECONDARY_FONT(17);
    self.raisedAmountCell.textLabel.font = PELOTONIA_FONT(21);
    self.raisedAmountCell.detailTextLabel.font = PELOTONIA_SECONDARY_FONT(17);
    self.storyTextView.font = PELOTONIA_SECONDARY_FONT(17);
    
    if (self.following) {
        [self.followButton setTitle:@"Unfollow"];
    }
    else {
        [self.followButton setTitle:@"Follow"];
    }
    
    // this masks the photo to the tableviewcell
    self.nameAndRouteCell.imageView.layer.masksToBounds = YES;
    self.nameAndRouteCell.imageView.layer.cornerRadius = 5.0;
    
    // now we resize the photo and the cell so that the photo looks right
    __block UIActivityIndicatorView *activityIndicator;
    [self.nameAndRouteCell.imageView addSubview:activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]];
    activityIndicator.center = self.nameAndRouteCell.imageView.center;
    [activityIndicator startAnimating];
    
    [self.nameAndRouteCell.imageView setImageWithURL:[NSURL URLWithString:self.rider.riderPhotoUrl]
            placeholderImage:[UIImage imageNamed:@"pelotonia-icon.png"]
                   completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType)
     {
         if (error != nil) {
             NSLog(@"ProfileTableViewController::configureView error: %@", error.localizedDescription);
         }
         [activityIndicator removeFromSuperview];
         activityIndicator = nil;
         [self.nameAndRouteCell layoutSubviews];
     }];
    
    
    // re-layout subviews so that the image auto-adjusts
    [self.nameAndRouteCell layoutSubviews];
}

- (void)postAlert:(NSString *)msg {
    // alert that they need to authorize first
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thank you for your Pledge"
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)sendPledgeMailToEmail:(NSString *)email withAmount:(NSString *)amount
{
    if (email && amount) {
        
        NSLog(@"Email sent to: %@", email);
        NSLog(@"You have decided to sponsor %@ the amount %@", self.rider.name, amount);
        
        MFMailComposeViewController *mailComposer;
        mailComposer  = [[MFMailComposeViewController alloc] init];
        mailComposer.mailComposeDelegate = self;
        [mailComposer setToRecipients:[NSArray arrayWithObject:email]];
        [mailComposer setModalPresentationStyle:UIModalPresentationFormSheet];
        [mailComposer setSubject:@"Thank you for your support of Pelotonia"];
        
        NSString *msg = [NSString stringWithFormat:@"<HTML><BODY>Thank you for your <a href=%@>pledge</a> of %@ to my Pelotonia ride.<br/><br/>Pelotonia is a grassroots bike tour with one goal: to end cancer. More than 10,000 supporters are expected to be a part of Pelotonia 12 on August 10-12, 2012. The ride will span two days and will cover as many as 180 miles. In its first three years, Pelotonia has attracted over 8,300 riders from 38 states, over 2,800 volunteers, hundreds of thousands of donors and raised $25.4 million for cancer research. In 2011 alone, a record $13.1 million was raised. Because operational expenses are covered by Pelotonia funding partners, 100%% of every dollar raised is donated directly to life-saving cancer research at The Ohio State University Comprehensive Cancer Center-James Cancer Hospital and Solove Research Institute. I am writing to ask you to help me raise funds for this incredible event. Large or small, every donation makes a difference.<br/><br/>We all know someone who has been affected by cancer. One of every two American men and one of every three American women will be diagnosed with cancer at some point in their lives. By supporting Pelotonia and me, you will help improve lives through innovative research with the ultimate goal of winning the war against cancer. I would love to have your support, as this is truly a unique opportunity to be a part of something special.<br/><br/>When you follow the link below, you will find my personal rider profile and a simple and secure way to make any size donation you wish.<br/><br/>Think of this as a donation not to me, or Pelotonia, but directly to The OSUCCC-James to fund cancer research. Please consider supporting my effort and this great cause. My rider profile can be found at the following link: <a href='%@'>%@</a><br/><br/>Thanks for the support!<br/><br/>Sincerely,<br/>%@</BODY></HTML>", self.rider.donateUrl, amount, self.rider.donateUrl, self.rider.donateUrl, self.rider.name];
        
        NSLog(@"msgBody: %@", msg);
        [mailComposer setMessageBody:msg isHTML:YES];
        [self presentModalViewController:mailComposer animated:YES];
    }

    
}

#pragma mark - MFMailComposeViewDelegate methods
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    if(error) {
        NSLog(@"ERROR - mailComposeController: %@", [error localizedDescription]);
    }
    [self dismissModalViewControllerAnimated:YES];
}


- (IBAction)followRider:(id)sender {
    // add the current rider to the main list of riders
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    RiderDataController *dataController = appDelegate.riderDataController;
    
    if (!self.following) {
        [dataController addObject:self.rider];
    }
    else {
        [dataController removeObject:self.rider];
    }
    [self configureView];
}

- (void)shareOnFacebook
{
    NSLog(@"Sharing on Facebook: %@", self.rider.name);
    
    // use the SHKFacebook object to share progress directly on FB
    SHKItem *item = [SHKItem URL:[NSURL URLWithString:self.rider.profileUrl] title:[NSString stringWithFormat:@"Please support %@'s Pelotonia Ride", self.rider.name] contentType:SHKURLContentTypeWebpage];

    [item setText:[NSString stringWithFormat:@"Supportive message here"]];
    
    [item setFacebookURLShareDescription:@"Pelotonia is a grassroots bike tour with one goal: to end cancer. Donations can be made in support of riders and will fund essential research at The James Cancer Hospital and Solove Research Institute. See the purpose, check the progress, make a difference."];
    
    [item setFacebookURLSharePictureURI:@"http://pelotonia.resource.com/facebook/images/pelotonia_352x310_v2.png"];
    
    [SHKFacebook shareItem:item];
}

- (void)shareOnTwitter
{
    NSLog(@"Sharing on Twitter: %@", self.rider.name);
    
    // use the SHKFacebook object to share progress directly on FB
    SHKItem *item = [SHKItem URL:[NSURL URLWithString:self.rider.profileUrl] title:[NSString stringWithFormat:@"Please support %@'s Pelotonia Ride at %@", self.rider.name, self.rider.profileUrl] contentType:SHKURLContentTypeWebpage];
    
    [SHKTwitter shareItem:item];
}


#pragma mark -- PullToRefreshDelegate
- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view;
{
    [self performSelectorInBackground:@selector(refreshRider) withObject:nil];
}

-(void)manualRefresh:(NSNotification *)notification
{
    self.tableView.contentOffset = CGPointMake(0, -65);
    [pull setState:PullToRefreshViewStateLoading];
    [self performSelectorInBackground:@selector(refreshRider) withObject:nil];
}

#pragma mark -- PhotoUpdateDelegate
- (void)riderPhotoDidUpdate:(UIImage *)image
{
    [self configureView];
}

- (void)riderPhotoThumbDidUpdate:(UIImage *)image
{
    [self configureView];
}

#pragma mark -- SendPledgeViewControllerDelegate
- (void)sendPledgeModalViewControllerDidCancel:(SendPledgeModalViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)sendPledgeModalViewControllerDidFinish:(SendPledgeModalViewController *)controller
{

    NSString *email = controller.textViewName.text;
    NSString *amount = controller.textViewAmount.text;
    
    [controller dismissViewControllerAnimated:YES completion:^(void){
        [self sendPledgeMailToEmail:email withAmount:amount];
    }];
}

#pragma mark -- sharing
- (void)showShareActionSheet
{
    NSString *actionSheetTitle = [NSString stringWithFormat:NSLocalizedString(@"Choose a Social Network", nil)];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:actionSheetTitle delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (NSString *title in [sharersTable allKeys]) {
        [actionSheet addButtonWithTitle:title];
    }
    [actionSheet addButtonWithTitle:@"Cancel"];
    actionSheet.cancelButtonIndex = actionSheet.numberOfButtons-1;
    
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    actionSheet.tag = kShareActionSheet;
    
    // Display the action sheet
    [actionSheet showFromBarButtonItem:self.followButton animated:YES];
}

#pragma mark -- UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == kShareActionSheet) {
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            // this is what we do when we share...
            NSString *sharersName = [actionSheet buttonTitleAtIndex:buttonIndex];
            NSString *selectorName = [sharersTable objectForKey:sharersName];
            
            // call the appropriate selector
            if (selectorName) {
                [self performSelector:NSSelectorFromString(selectorName)];
            }
        }
    }
}



@end
