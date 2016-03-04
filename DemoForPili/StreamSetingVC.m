//
//  StreamSetingVC.m
//  DemoForPili
//
//  Created by   何舒 on 16/3/3.
//  Copyright © 2016年 Aaron. All rights reserved.
//

#import "StreamSetingVC.h"
#import "PLViewController.h"

@interface StreamSetingVC ()<UITextFieldDelegate,UIActionSheetDelegate>

@property (nonatomic, assign) NSInteger quarlityNum;
@property (nonatomic, assign) NSInteger audioQualityNum;
@property (nonatomic, strong) UIActionSheet * qualityAciongSheet;
@property (nonatomic, strong) UIActionSheet * audioActionSheet;

@end

@implementation StreamSetingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.quarlityNum = 1;
    self.title = @"配置信息";
    // Do any additional setup after loading the view from its nib.
}
- (IBAction)chooseQualityAction:(id)sender {
    self.qualityAciongSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"清晰度选择"
                                  delegate:self
                                  cancelButtonTitle:@"取消"
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:@"low1",@"low2",@"low3",@"Medium1",@"Medium2",@"Medium3",@"High1",@"High2",@"High3",nil];
    self.qualityAciongSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    self.qualityAciongSheet.tag = 1000;
    [self.qualityAciongSheet showInView:self.view];
}
- (IBAction)chooseAudioAcion:(id)sender {
    self.audioActionSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"音频清晰度选择"
                                  delegate:self
                                  cancelButtonTitle:@"取消"
                                  destructiveButtonTitle:nil
                                otherButtonTitles:@"High1",@"High2",nil];
    self.audioActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    self.audioActionSheet.tag = 1001;
    [self.audioActionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet == self.audioActionSheet) {
        self.audioQualityNum = (buttonIndex == 2)?0:buttonIndex;
        [self.chooseAudioQualityBtn setTitle:[actionSheet buttonTitleAtIndex:self.audioQualityNum]forState:UIControlStateNormal];
    }else{
        //清晰度
        self.quarlityNum = (buttonIndex == 9)?1:buttonIndex;
        [self.chooseQualityBtn setTitle:[actionSheet buttonTitleAtIndex:self.quarlityNum]forState:UIControlStateNormal];
    }
    
}
- (IBAction)startAction:(id)sender {
    if (self.keytextfield.text == nil) {
        [SVProgressHUD showAlterMessage:@"题目不能为空"];
        return;
    }
    PLViewController *plVC = [[PLViewController alloc] initWithKey:self.keytextfield.text withQuality:self.quarlityNum withAudioQualiyt:self.audioQualityNum];
    [self.navigationController pushViewController:plVC animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
