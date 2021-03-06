//
//  FCMessagesViewController.m
//  FireChat
//
//  Created by soknaly on 10/21/16.
//  Copyright © 2016 Sokna Ly. All rights reserved.
//

#import "FCMessagesViewController.h"
#import "FCMessage.h"
#import "JSQMessage.h"
#import "FCPhotoMediaItem.h"
#import "JSQMessagesBubbleImage.h"
#import "JSQMessagesBubbleImageFactory.h"
#import "SDImageCache.h"

static NSString * const kJSQDemoAvatarDisplayNameDuke = @"Duke";
static NSString * const kJSQDemoAvatarDisplayNameSokna = @"Sokna Ly";

static NSString * const kJSQDemoAvatarIdDuke = @"053496-4509-289";
static NSString * const kJSQDemoAvatarIdSokna = @"707-8956784-57";

@interface FCMessagesViewController ()<
UIImagePickerControllerDelegate,
UINavigationControllerDelegate
>

@property (nonatomic, strong) FCUser *currentUser;

@property (nonatomic, strong) NSMutableArray<FCMessage *>* messages;

@property (nonatomic, strong) NSDictionary<NSString *,NSString *>* images;

@property (nonatomic, strong) NSTimer *typingTimer;

@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;

@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;

@end

@implementation FCMessagesViewController

- (FCUser *)currentUser {
  if (!_currentUser) {
    FIRUser *currentUser = [FIRAuth auth].currentUser;
    _currentUser = [[FCUser alloc] init];
    _currentUser.uid = currentUser.uid;
    _currentUser.displayName = currentUser.displayName;
    _currentUser.emailAddress = currentUser.email;
    _currentUser.photoURL = currentUser.photoURL;
  }
  return _currentUser;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = self.chat.recipient.displayName;
  self.senderId = self.currentUser.uid;
  self.senderDisplayName = self.currentUser.uid;
  self.inputToolbar.contentView.textView.delegate = self;
  JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
  self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor messageBubbleLightGrayColor]];
  self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor mainColor]];
  [self setupMessage];
}

- (void)setupMessage {
  self.messages = [NSMutableArray array];
  FIRDatabase *database = [FIRDatabase database];
  FIRDatabaseReference *messagesRef = [[database referenceWithPath:@"messages"] child:self.chat.uid];
  [messagesRef observeEventType:FIRDataEventTypeChildAdded
                      withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                        NSString *senderID = snapshot.value[@"senderID"];
                        FCUser *user = nil;
                        if ([senderID isEqualToString:self.senderId]) {
                          user = self.currentUser;
                        } else {
                          user = self.chat.recipient;
                        }
                        FCMessage *message = nil;
                        NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:labs([snapshot.value[@"timestamp"] integerValue])];
                        if ([snapshot.value[@"isMedia"] boolValue]) {
                          FCPhotoMediaItem *photoItem = [[FCPhotoMediaItem alloc] initWithURL:[NSURL URLWithString:snapshot.value[@"message"]]];
                          message = [[FCMessage alloc] initWithSenderId:snapshot.value[@"senderID"]
                                                      senderDisplayName:self.senderDisplayName
                                                                   date:date
                                                                  media:photoItem];
                        } else {
                          message = [[FCMessage alloc] initWithUser:user
                                                               date:date
                                                               text:snapshot.value[@"message"]];
                        }
                        
                        [self.messages addObject:message];
                        [self finishReceivingMessageAnimated:YES];
                      }];
  
  [[FCAPIService sharedServiced] observeTypingStatusForChat:self.chat
                                                actionBlock:^(BOOL isTyping) {
                                                  if (isTyping) {
                                                    self.showTypingIndicator = YES;
                                                    [self scrollToBottomAnimated:YES];
                                                  } else {
                                                    self.showTypingIndicator = NO;
                                                  }
                                                }];
}

#pragma mark - CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
  return [self.messages objectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
  
  JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
  
  if ([message.senderId isEqualToString:self.senderId]) {
    return self.outgoingBubbleImageData;
  }
  
  return self.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return nil;
}


- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  
  JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
  
  
  FCMessage *msg = [self.messages objectAtIndex:indexPath.item];
  
  if (!msg.isMediaMessage) {
    
    if ([msg.senderId isEqualToString:self.senderId]) {
      cell.textView.textColor = [UIColor blackColor];
    }
    else {
      cell.textView.textColor = [UIColor whiteColor];
    }
    
    cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                          NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
  }
  NSURL *imageUrl = nil;
  if ([msg.senderId isEqualToString:self.senderId]) {
    imageUrl = self.currentUser.photoURL;
  } else {
    imageUrl = self.chat.recipient.photoURL;
  }
  cell.avatarImageView.layer.cornerRadius = CGRectGetWidth(cell.avatarImageView.frame)/2;
  cell.avatarImageView.layer.masksToBounds = YES;
  [cell.avatarImageView sd_setImageWithURL:imageUrl
                          placeholderImage:[UIImage profilePlaceholderImage]];
  return cell;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return self.messages.count;
}

#pragma mark -

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  [self.inputToolbar toggleSendButtonEnabled];
  if (self.typingTimer) {
    [self.typingTimer invalidate];
    self.typingTimer = nil;
  } else {
    [[FCAPIService sharedServiced] sendTypingStatusForChat:self.chat];
  }
  self.typingTimer = [NSTimer scheduledTimerWithTimeInterval:4.0
                                                      target:self
                                                    selector:@selector(stopSendingUserTpyingIfNeeded)
                                                    userInfo:nil
                                                     repeats:NO];
  
  return YES;
}

- (void)stopSendingUserTpyingIfNeeded {
  [self.typingTimer invalidate];
  self.typingTimer = nil;
  [[FCAPIService sharedServiced] sendStopTypingStatusForChat:self.chat];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
  UIImage *image = info[UIImagePickerControllerEditedImage];
  [picker dismissViewControllerAnimated:YES completion:nil];
  [[FCAPIService sharedServiced] uploadImage:image
                                    withName:[NSString stringWithFormat:@"%f",round([NSDate timeIntervalSinceReferenceDate])]
                                    progress:^(NSProgress *progress) {
                                      [FCProgressHUD showProgress:progress.fractionCompleted status:@"Uploading Image"];
                                    }
                                     success:^(NSURL *imageURL) {
                                       [FCProgressHUD dismiss];
                                       NSDate *nowDate = [NSDate date];
                                       [[FCAPIService sharedServiced] sendMessageWithText:imageURL.absoluteString
                                                                                 senderID:self.senderId
                                                                                     date:nowDate
                                                                                  isMedia:YES
                                                                                  forChat:self.chat];
                                       [self finishSendingMessage];
                                       
                                     }
                                     failure:^(NSError *error) {
                                       
                                     }];
}

#pragma mark - JSQInputToolbarDelegate

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date {
  
  [[FCAPIService sharedServiced] sendMessageWithText:text
                                            senderID:senderId
                                                date:date
                                             isMedia:NO
                                             forChat:self.chat];
  [self finishSendingMessageAnimated:YES];
}

- (void)didPressAccessoryButton:(UIButton *)sender {
  [FCAlertController showImagePickerInViewController:self
                                            delegate:self];
}


@end
