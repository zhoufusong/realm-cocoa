//
//  TableViewController.m
//  RealmExamples
//
//  Created by Tim Oliver on 7/04/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

#import "TableViewController.h"
#import <Realm/Realm.h>

// Realm model object
@interface DemoObject : RLMObject
@property NSString *title;
@property NSDate   *date;
@end

@implementation DemoObject
// None needed
@end

// ------------------------------

@interface TableViewController ()

- (void)addButtonTapped:(id)sender;

@end

@implementation TableViewController

- (void)viewDidLoad
{
    self.title = @"ChangeNotifications";
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonTapped:)];
    self.navigationItem.leftBarButtonItem = addButton;
}

#pragma mark - Button Callbacks -
- (void)addButtonTapped:(id)sender
{
    
}

#pragma mark - Table View Data Source - 
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"TableCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
    }
    
    cell.textLabel.text = @"Title";
    cell.detailTextLabel.text = @"Subtitle";
    
    return cell;
}

#pragma mark - Table Delegate -
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    
}

@end
