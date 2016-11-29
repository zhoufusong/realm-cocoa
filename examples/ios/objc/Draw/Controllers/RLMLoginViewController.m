//
//  RLMLoginViewController.m
//  RealmExamples
//
//  Created by Tim Oliver on 11/28/16.
//  Copyright © 2016 Realm. All rights reserved.
//

#import "RLMLoginViewController.h"

#import "RLMLoginBackgroundView.h"
#import "RLMTableViewCell.h"

@interface RLMLoginViewController () <UITextFieldDelegate>

@property (nonatomic, assign) CGFloat keyboardHeight;
@property (nonatomic, strong) UITextField *hostNameField;
@property (nonatomic, strong) UITextField *userNameField;
@property (nonatomic, strong) UITextField *passwordField;

@property (nonatomic, strong) UIButton *connectButton;
@property (nonatomic, strong) UIActivityIndicatorView *activityindicator;

- (void)buttonTapped:(id)sender;

- (void)loadTextFieldViews;
- (void)loadConnectButton;

+ (UIImage *)cellBackgroundImageBottom:(BOOL)bottom;

// Keyboard Handling
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;

@end

@implementation RLMLoginViewController

- (instancetype)init
{
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        
    }
    
    return self;
}

#pragma mark - View Creation -

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundView = [[RLMLoginBackgroundView alloc] init];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    //Suppress the separator line at the bottom
    UIView *fillerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,1,1)];
    self.tableView.tableFooterView = fillerView;
    
    [self loadTextFieldViews];
    [self loadConnectButton];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)loadTextFieldViews
{
    UITextField *(^newTextFieldBlock)() = ^UITextField *{
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectZero];
        textField.delegate = self;
        textField.font = [UIFont systemFontOfSize:20.0f];
        textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        return textField;
    };
    
    self.hostNameField = newTextFieldBlock();
    self.hostNameField.placeholder = @"localhost";
    
    self.passwordField = newTextFieldBlock();
    self.passwordField.placeholder = @"password";
    self.passwordField.secureTextEntry = YES;
    
    self.userNameField = newTextFieldBlock();
    self.userNameField.placeholder = @"demo@realm.io";
}

- (void)loadConnectButton
{
    if (self.connectButton == nil) {
        self.connectButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.connectButton.frame = (CGRect){0, 0, 520.0f, 64.0f};
        self.connectButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        self.connectButton.tintColor = [UIColor whiteColor];
        self.connectButton.titleLabel.font = [UIFont boldSystemFontOfSize:20.0f];
        self.connectButton.backgroundColor = [UIColor colorWithRed:242.0f/255.0f green:81.0f/255.0f blue:146.0f/255.0f alpha:1.0f];
        self.connectButton.clipsToBounds = YES;
        self.connectButton.layer.cornerRadius = 20.0f;
        [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
        [self.connectButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (self.activityindicator == nil) {
        self.activityindicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.activityindicator.hidden = YES;
        self.activityindicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        self.activityindicator.center = self.connectButton.center;
        [self.connectButton addSubview:self.activityindicator];
    }
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,600,64.0f)];
    [containerView addSubview:self.connectButton];
    self.connectButton.center = containerView.center;
    
    self.tableView.tableFooterView = containerView;
}

- (void)buttonTapped:(id)sender
{
    if (self.connectButtonTapped) {
        self.connectButtonTapped();
    }
}

#pragma mark - Keyboard Notifications - 
- (void)keyboardWillShow:(NSNotification *)notification
{
//    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
//    self.keyboardHeight = endFrame.size.height;
//    
//    
//    [UIView animateWithDuration:0.5f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.1f options:0 animations:^{
//        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.keyboardHeight, 0);
//    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
//    self.keyboardHeight = 0.0f;
//    
//    [UIView animateWithDuration:0.5f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.1f options:0 animations:^{
//        self.tableView.contentInset = UIEdgeInsetsZero;
//    } completion:nil];
}

#pragma mark - Accessors -
- (void)setLoading:(BOOL)loading
{
    _loading = loading;
    
    if (_loading) {
        [self.connectButton setTitle:@"" forState:UIControlStateNormal];
        self.activityindicator.hidden = NO;
        [self.activityindicator startAnimating];
    }
    else {
        [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
        self.activityindicator.hidden = YES;
        [self.activityindicator stopAnimating];
    }
}

- (NSString *)hostName
{
    return self.hostNameField.text.length > 0 ? self.hostNameField.text : self.hostNameField.placeholder;
}

- (NSString *)userName
{
    return self.userNameField.text.length > 0 ? self.userNameField.text : self.userNameField.placeholder;
}

- (NSString *)password
{
    return self.passwordField.text.length > 0 ? self.passwordField.text : self.passwordField.placeholder;
}

#pragma mark - Table View Data Source -

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat verticalPadding = (self.tableView.frame.size.height - self.tableView.contentSize.height) * 0.5f;
    return verticalPadding;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(tintColor)]) {
        if (tableView == self.tableView) {
            CGFloat cornerRadius = 5.f;
            cell.backgroundColor = UIColor.clearColor;
            CAShapeLayer *layer = [[CAShapeLayer alloc] init];
            CGMutablePathRef pathRef = CGPathCreateMutable();
            CGRect bounds = CGRectInset(cell.bounds, 10, 0);
            BOOL addLine = NO;
            if (indexPath.row == 0 && indexPath.row == [tableView numberOfRowsInSection:indexPath.section]-1) {
                CGPathAddRoundedRect(pathRef, nil, bounds, cornerRadius, cornerRadius);
            } else if (indexPath.row == 0) {
                CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds));
                CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds), CGRectGetMidX(bounds), CGRectGetMinY(bounds), cornerRadius);
                CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius);
                CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds));
                addLine = YES;
            } else if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section]-1) {
                CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds));
                CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds), CGRectGetMidX(bounds), CGRectGetMaxY(bounds), cornerRadius);
                CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius);
                CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds));
            } else {
                CGPathAddRect(pathRef, nil, bounds);
                addLine = YES;
            }
            layer.path = pathRef;
            CFRelease(pathRef);
            layer.fillColor = [UIColor colorWithWhite:1.f alpha:0.8f].CGColor;
            
            if (addLine == YES) {
                CALayer *lineLayer = [[CALayer alloc] init];
                CGFloat lineHeight = (1.f / [UIScreen mainScreen].scale);
                lineLayer.frame = CGRectMake(CGRectGetMinX(bounds)+10, bounds.size.height-lineHeight, bounds.size.width-10, lineHeight);
                lineLayer.backgroundColor = tableView.separatorColor.CGColor;
                [layer addSublayer:lineLayer];
            }
            UIView *testView = [[UIView alloc] initWithFrame:bounds];
            [testView.layer insertSublayer:layer atIndex:0];
            testView.backgroundColor = UIColor.clearColor;
            cell.backgroundView = testView;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellidentifier = @"Cell";
    RLMTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellidentifier];
    if (cell == nil) {
        cell = [[RLMTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellidentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont systemFontOfSize:20.0f];
        cell.textLabel.textColor = [UIColor colorWithWhite:0.5f alpha:1.0f];
    }
    
    cell.layoutMargins = UIEdgeInsetsMake(0, 0, 0, 0);
    cell.backgroundColor = [UIColor whiteColor];
    
    CGRect textFieldframe = cell.bounds;
    textFieldframe.origin.x = 150.0f;
    textFieldframe.size.height = cell.contentView.frame.size.height;
    textFieldframe.size.width -= 15.0f;
    textFieldframe.origin.y = (cell.contentView.frame.size.height - textFieldframe.size.height) * 0.5f;

    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Host Name:";
            self.hostNameField.frame = textFieldframe;
            [cell.contentView addSubview:self.hostNameField];
            break;
        case 1:
            cell.textLabel.text = @"User Name:";
            self.userNameField.frame = textFieldframe;
            [cell.contentView addSubview:self.userNameField];
            break;
        case 2:
            cell.textLabel.text = @"Password:";
            self.passwordField.frame = textFieldframe;
            [cell.contentView addSubview:self.passwordField];
            break;
    }
    
    return cell;
}

@end
