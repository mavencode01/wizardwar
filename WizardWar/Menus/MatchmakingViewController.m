//
//  MatchmakingViewController.m
//  WizardWar
//
//  Created by Sean Hess on 5/17/13.
//  Copyright (c) 2013 The LAB. All rights reserved.
//

#import "MatchmakingViewController.h"
#import "WizardDirector.h"
#import "MatchLayer.h"
#import "Challenge.h"
#import "NSArray+Functional.h"
#import "FirebaseCollection.h"
#import "FirebaseConnection.h"
#import "MatchViewController.h"
#import "User.h"
#import "LobbyService.h"
#import "UserService.h"
#import "ChallengeService.h"
#import "AccountViewController.h"
#import "LocationService.h"
#import "UserFriendService.h"
#import <ReactiveCocoa.h>
#import "ComicZineDoubleLabel.h"

@interface MatchmakingViewController () <AccountFormDelegate>
@property (nonatomic, weak) IBOutlet UITableView * tableView;
@property (weak, nonatomic) IBOutlet UIView *accountView;

@property (nonatomic, readonly) NSArray * challenges;
@property (nonatomic, readonly) NSArray * users;

@property (nonatomic, strong) FirebaseConnection* connection;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UILabel *userLoginLabel;

@property (nonatomic, readonly) User * currentUser;
@property (strong, nonatomic) MatchLayer * match;

@end

@implementation MatchmakingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Matchmaking";
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationItem.titleView = [ComicZineDoubleLabel titleView:self.title navigationBar:self.navigationController.navigationBar];
    
    // CHECK AUTHENTICATED
    if ([UserService shared].isAuthenticated) {
        [self connect];
    }
    else {
        AccountViewController * accounts = [AccountViewController new];
        accounts.delegate = self;
        [self.navigationController presentViewController:accounts animated:YES completion:nil];
    }
}

- (void)connect {
    [LocationService.shared connect];
    [ChallengeService.shared connect];

    __weak MatchmakingViewController * wself = self;
    
    // LOBBY
    self.accountView.hidden = YES;
//    self.activityView.hidesWhenStopped = YES;
//    if (!LobbyService.shared.joined)
//        [self.activityView startAnimating];
//    self.userLoginLabel.text = self.currentUser.name;
//    [RACAble(LobbyService.shared, joined) subscribeNext:^(id x) {
//        [self.activityView stopAnimating];
//    }];
    
    [LobbyService.shared.updated subscribeNext:^(id x) {
        [wself.tableView reloadData];
    }];
    
    [UserService.shared.updated subscribeNext:^(id x) {
        [wself.tableView reloadData];
    }];
    
    
    [RACAble(LocationService.shared, location) subscribeNext:^(id x) {
        [wself didUpdateLocation];
    }];
    [self didUpdateLocation];
    
    // CHALLENGES
    [ChallengeService.shared.updated subscribeNext:^(id x) {
        NSLog(@"UPDATED CHALLENGES");
        [wself.tableView reloadData];
    }];
}


- (void)viewDidAppear:(BOOL)animated {}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)disconnect {
    [self leaveLobby];
}

- (void)reconnect {
    [self joinLobby];
}


#pragma mark - Location
-(void)didUpdateLocation {
    
    if (LocationService.shared.hasLocation) {
        self.currentUser.location = LocationService.shared.location;
    }
    
    if (LocationService.shared.hasLocation || LocationService.shared.denied) {
        [self joinLobby];
    }
}


#pragma mark - AccountFormDelegate
-(void)didCancelAccountForm {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
    
}
-(void)didSubmitAccountForm:(NSString *)name {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self connect];
}

#pragma mark - Login

- (IBAction)didTapLogin:(id)sender {
    
}

- (NSArray*)challenges {
    return ChallengeService.shared.myChallenges.allValues;
}

- (NSArray*)localUsers {
    return LobbyService.shared.localUsers.allValues;
}

- (User*)currentUser {
    return UserService.shared.currentUser;
}

- (NSArray*)friends {
    
    // TODO switch to be a set or dictionary instead of an array
    // that way they CAN'T be in both lists
    
    // We don't want to show anyone who is already in the local list!
    NSArray * unsortedFriends = [UserFriendService.shared.friends.allValues filter:^BOOL(User * user) {
        return (![LobbyService.shared userIsLocal:user]);
    }];
    
    return [unsortedFriends sortedArrayUsingComparator:^NSComparisonResult(User * user, User * buser) {
        if (user.friendCount > buser.friendCount) return NSOrderedAscending;
        else if (user.friendCount < buser.friendCount) return NSOrderedDescending;
        else return NSOrderedSame;
    }];
}

- (NSArray*)strangers {
    // for now, show every user in the system
    // wait, this isn't a solution
    return UserService.shared.allUsers.allValues;
}


#pragma mark - Firebase stuff

- (void)joinLobby
{
    [LobbyService.shared joinLobby:self.currentUser location:LocationService.shared.location];
}

- (void)leaveLobby {
    [LobbyService.shared leaveLobby:self.currentUser];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return [self.challenges count];
    } else if (section == 1){
        return [self.localUsers count];
    } else if (section == 2) {
        return [self.friends count];
    } else {
        return [self.strangers count];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    if (section == 0) return @"Challenges";
//    else if (section == 1) return @"Local Users";
//    else return @"Friends";
    return nil;
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return [self tableView:tableView challengeCellForRowAtIndexPath:indexPath];
    } else {
        User * user = nil;

        if (indexPath.section == 1) {
            user = self.localUsers[indexPath.row];
        } else if (indexPath.section == 2) {
            user = self.friends[indexPath.row];
        } else {
            user = self.strangers[indexPath.row];
        }
        return [self tableView:tableView userCellForUser:user];
    }
}

-(UITableViewCell*)tableView:(UITableView *)tableView userCellForUser:(User*)user {
    static NSString *CellIdentifier = @"UserCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    UIColor * backgroundColor = [UIColor colorWithWhite:0.784 alpha:1.000];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.contentView.backgroundColor = backgroundColor;
        cell.textLabel.textColor = [UIColor colorWithWhite:0.149 alpha:1.000];
    }
    
    cell.textLabel.text = user.name;
    
    if ([LobbyService.shared userIsOnline:user])
        cell.textLabel.textColor = [UIColor greenColor];
    else
        cell.textLabel.textColor = [UIColor darkTextColor];
    
    cell.imageView.image = [UIImage imageNamed:@"user.jpg"];
    UILabel * accessory = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 43)];
    accessory.text = @"FRIEND";
    accessory.font = [UIFont boldSystemFontOfSize:14];
    accessory.backgroundColor = backgroundColor;
    accessory.textAlignment = NSTextAlignmentRight;
    cell.accessoryView = accessory;
    
    NSString * games = [NSString stringWithFormat:@"%i Games", user.friendCount];
    
    CLLocationDistance dl = [LocationService.shared distanceFrom:user.location];
    NSString * distance = (dl > 0) ? [NSString stringWithFormat:@"%@, ", [LocationService.shared distanceString:dl]] : @"";
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@%@", distance, games];
    return cell;
}

-(UITableViewCell*)tableView:(UITableView *)tableView challengeCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"InviteCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.contentView.backgroundColor = [UIColor colorWithRed:0.490 green:0.706 blue:0.275 alpha:1.000];
        cell.textLabel.textColor = [UIColor colorWithWhite:0.149 alpha:1.000];        
    }
    
    Challenge * challenge = self.challenges[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ vs %@", [self nameOrYou:challenge.main.name], [self nameOrYou:challenge.opponent.name]];
    
    return cell;
}

- (NSString*)nameOrYou:(NSString*)name {
    if ([name isEqualToString:self.currentUser.name]) return @"You";
    else return name;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
        [self didSelectChallenge:self.challenges[indexPath.row]];
    else if (indexPath.section == 1)
        [self didSelectUser:self.localUsers[indexPath.row]];
    else if (indexPath.section == 2)
        [self didSelectUser:self.friends[indexPath.row]];
    else
        [self didSelectUser:self.strangers[indexPath.row]];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didSelectUser:(User*)user {
    
    BOOL isOnline = [LobbyService.shared userIsOnline:user];

    // Issue the challenge
    Challenge * challenge = [ChallengeService.shared user:self.currentUser challengeOpponent:user isRemote:!isOnline];
    [self joinMatch:challenge];
    [UserFriendService.shared user:UserService.shared.currentUser addChallenge:challenge];
}

- (void)didSelectChallenge:(Challenge*)challenge {
    [self joinMatch:challenge];
}

- (void)joinMatch:(Challenge*)challenge {
    NSLog(@"JOIN THE READY SCREEN %@", challenge.matchId);    
    MatchViewController * match = [MatchViewController new];
    [match startChallenge:challenge currentWizard:UserService.shared.currentWizard];
    [self.navigationController presentViewController:match animated:YES completion:nil];
}

- (void)dealloc {
    // don't worry about disconnecting. If you aren't THERE, it's ok
}

@end
