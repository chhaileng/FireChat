//
//  FCGroupTableViewCell.h
//  FireChat
//
//  Created by soknaly on 10/22/16.
//  Copyright © 2016 Sokna Ly. All rights reserved.
//

#import "FCBaseTableViewCell.h"
#import "FCGroup.h"

@interface FCGroupTableViewCell : FCBaseTableViewCell

- (void)populateWithGroup:(FCGroup *)chat;

@end
