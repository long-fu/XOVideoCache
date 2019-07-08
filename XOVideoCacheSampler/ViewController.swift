//
//  ViewController.swift
//  XOVideoCacheSampler
//
//  Created by luo fengyuan on 2019/7/1.
//  Copyright © 2019 luo fengyuan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var video1Button: UIButton!
    
    @IBOutlet weak var video2Button: UIButton!
    
    @IBOutlet weak var video3Button: UIButton!
    
    @IBOutlet weak var video4Button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        video1Button.addTarget(self, action: #selector(__buttonClicked(_:)), for: UIControl.Event.touchUpInside)
        video2Button.addTarget(self, action: #selector(__buttonClicked(_:)), for: UIControl.Event.touchUpInside)
        video3Button.addTarget(self, action: #selector(__buttonClicked(_:)), for: UIControl.Event.touchUpInside)
        video4Button.addTarget(self, action: #selector(__buttonClicked(_:)), for: UIControl.Event.touchUpInside)
        // Do any additional setup after loading the view.
    }

    @objc
    private
    func __buttonClicked(_ sender: UIButton?) {
        guard let button = sender else {
            return
        }
        let vc = PlayVideoViewController()
        if button == video1Button {
            vc.resourceURL = URL(string: "https://vodm0pihssv.vod.126.net/edu-video/nos/mp4/2017/4/2/1006075895_7ef266a2-85f6-4d8d-bb21-3b9332c342f4_sd.mp4")!
        }
        else if button == video2Button {
            vc.resourceURL = URL(string: "https://apd-6da2d2ea49ade3248ca234fb8d8bae58.v.smtcdns.com/vweishi.tc.qq.com/AO5GtBLZz7QFEvE2LM01SnkfXoGNHfRBS_Uy95paEgY0/szg_10167773_40000_1b349e70032744309573336427a77bd6.f10.mp4?sdtfrom=v1103&guid=e737d5ae0915fdc9b2cc873c22147fef&vkey=BA1AB085D38353999F76C09D7E1A3AE11494A3694FCB04CEBBEF94E0A50EE10DD576086F64711AF2E718F5A407F41C0A56A78B9F1E1D2182E748C6B5B4186F0FE0F02F35923F3299B4877DF68A91E701721A7899108C828CD1FB7F47827240642E9506E6F836D9A5DB2A6D61DC23C6B47017D5BC020569350F8DE18ED4127FE7")!
        }
        else if button == video3Button {
            vc.resourceURL = URL(string: "https://apd-2302da32dd361333d3766a61badbd4e3.v.smtcdns.com/vweishi.tc.qq.com/AEApKWP0Cpl8fnkapa4KoHQX1-su8wdFn8MFmBPlj5Eo/szg_42622107_40000_4d2c2090c980422c861e4f26fd68418f.f10.mp4?sdtfrom=v1103&guid=e737d5ae0915fdc9b2cc873c22147fef&vkey=2A84349C0817CEA02A679891BDE1CD06F733D2F58B24B39B9F253BC97F349AD054719B7581EA2D0F85421502E2A6B1434BD75952165665BBE95D9597319397A34F05D309C188D5A6E5906621133A698825AF0CABCB53F5178615268FF3344D838F74F67A739C97E8E5629E5F10B497CFD44D3952A0A0F059E6D373E834FF55A9")!
        }
        else if button == video4Button {
            vc.resourceURL = URL(string: "https://apd-6da2d2ea49ade3248ca234fb8d8bae58.v.smtcdns.com/vweishi.tc.qq.com/A57dKsI6Cl4Wv3O5gqLxN_FEyvf3DUum9BE39J67W1ro/szg_59949277_40000_ea0881e4ef4e46cf8a056698c08c9d3e.f10.mp4?sdtfrom=v1103&guid=e737d5ae0915fdc9b2cc873c22147fef&vkey=E745B893184B40AF4DF892A4E92BF1562EBEA4689185FA16EFCA7601DAA24AB0B4B314202CE629DDB447600AAE7627F6FE1E121DCB0CDDA47FB080EE15695B4180321249CC8F52AB1C7B06AD8687409ABB37BE5A4A3D44239F675F9E88B725DADCB02A9BFCCB4917A098B5C8B936CB8B3B873677385723C24F679BB632C773D5")!
        }
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    

}

