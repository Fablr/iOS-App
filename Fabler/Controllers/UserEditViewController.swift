//
//  UserEditViewController.swift
//  Fabler
//
//  Created by Christopher Day on 12/16/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import Eureka
import SCLAlertView

class UserEditViewController: FormViewController {

    // MARK: - UserEditViewController properties

    var user: User?

    // MARK: - UserEditViewController methods

    private func requestComplete(service: UserService, alert: SCLAlertViewResponder, showWarning: Bool, warningText: String) {
        if service.outstandingRequestCount() == 0 {
            self.setFormValues()
            alert.close()
            if showWarning {
                SCLAlertView().showWarning("Warning", subTitle: warningText)
            } else {
                SCLAlertView().showSuccess("Saved", subTitle: "", duration: 2.0)
            }
        }
    }

    func savePressed(cell: ButtonCellOf<String>, row: ButtonRow) {
        guard let user = self.user else {
            return
        }

        let alert = SCLAlertView().showWait("Updating profile", subTitle: "")
        var showWarning: Bool = false
        var warningText: String = "Unable to save profile."
        var close: Bool = true

        let values = form.values()
        var userName: String?
        var firstName: String?
        var lastName: String?
        var email: String?
        var birthday: NSDate?

        let service = UserService()

        //
        // Send username as seperate request for unique error.
        //
        if let value = values["Username"] as? String {
            userName = value == user.userName ? nil : value

            if let userName = userName {
                service.updateUsername(userName, user: user) { result in
                    if !result {
                        showWarning = true
                        warningText = "Username is already in use."
                    }

                    self.requestComplete(service, alert: alert, showWarning: showWarning, warningText: warningText)
                }

                close = false
            }
        }

        //
        // Send email as seperate request for unique error.
        //
        if let value = values["Email"] as? String {
            email = value == user.email ? nil : value

            if let email = email {
                service.updateEmail(email, user: user) { result in
                    if !result {
                        showWarning = true
                        warningText = "Email is already in use."
                    }

                    self.requestComplete(service, alert: alert, showWarning: showWarning, warningText: warningText)
                }

                close = false
            }
        }

        if let value = values["FirstName"] as? String {
            firstName = value == user.firstName ? nil : value
        }

        if let value = values["LastName"] as? String {
            lastName = value == user.lastName ? nil : value
        }

        if let value = values["Birthday"] as? NSDate {
            let interval: Int

            if user.birthday == nil {
                interval = 0
            } else {
                interval = NSCalendar.currentCalendar().components(NSCalendarUnit.Day, fromDate: user.birthday!, toDate: value, options: NSCalendarOptions()).day
            }

            birthday = interval == 0 ? nil : value
        }

        if firstName != nil || lastName != nil || birthday != nil {
            service.updateProfile(firstName, lastName: lastName, birthday: birthday, user: user) { result in
                if !result {
                    showWarning = true
                }

                self.requestComplete(service, alert: alert, showWarning: showWarning, warningText: warningText)
            }

            close = false
        }

        //
        // If no requests were sent close the waiting alertview.
        //
        if close {
            alert.close()
        }
    }

    func cancelPressed(cell: ButtonCellOf<String>, row: ButtonRow) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func setFormValues() {
        guard let user = self.user else {
            return
        }

        let birthday = (user.birthday != nil) ? user.birthday! : NSDate()
        let values: [String: Any?] = ["Username": user.userName, "FirstName": user.firstName, "LastName": user.lastName, "Email": user.email, "Birthday": birthday]
        self.form.setValues(values)
        self.tableView?.reloadData()
    }

    // MARK: - UIViewController methods

    override func viewDidLoad() {
        super.viewDidLoad()

        guard self.user != nil else {
            Log.info("Expected a user initiated via previous controller.")
            return
        }

        let blurEffect = UIBlurEffect(style: .Light)
        let veView = UIVisualEffectView(effect: blurEffect)
        veView.frame = self.view.bounds
        self.view.backgroundColor = .clearColor()
        self.view.insertSubview(veView, atIndex: 0)
        self.tableView?.backgroundColor = .clearColor()

        NameRow.defaultCellSetup = { cell, row in cell.tintColor = .fablerOrangeColor() }
        EmailRow.defaultCellSetup = { cell, row in cell.tintColor = .fablerOrangeColor() }
        DateRow.defaultCellSetup = { cell, row in cell.tintColor = .fablerOrangeColor() }

        self.navigationAccessoryView.tintColor = .fablerOrangeColor()

        self.form +++= Section()
            <<< NameRow("Username") {
                $0.title = "Username"
            }
            <<< NameRow("FirstName") {
                $0.title = "First name"
            }
            <<< NameRow("LastName") {
                $0.title = "Last name"
            }
            <<< EmailRow("Email") {
                $0.title = "Email"
            }
            <<< DateRow("Birthday") {
                $0.title = "Birthday"
                let formatter = NSDateFormatter()
                formatter.locale = .currentLocale()
                formatter.dateStyle = .ShortStyle
                $0.dateFormatter = formatter
            }

        self.form +++= Section()
            <<< ButtonRow("Save") {
                $0.title = $0.tag
                $0.onCellSelection(self.savePressed)
                $0.cellSetup { cell, row in
                    cell.tintColor = .fablerOrangeColor()
                    if let size = cell.textLabel?.font.pointSize {
                        cell.textLabel?.font = .boldSystemFontOfSize(size)
                    }
                }
            }

        self.form +++= Section()
            <<< ButtonRow("Cancel") {
                $0.title = $0.tag
                $0.onCellSelection(self.cancelPressed)
                $0.cellSetup { cell, row in
                    cell.tintColor = .fablerOrangeColor()
                }
            }

        self.setFormValues()
    }
}
