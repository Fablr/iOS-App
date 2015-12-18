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

    // MARK: - UserEditViewController members

    var user: User?

    var alertDisplayed: Bool = false

    // MARK: - UserEditViewController functions

    func cancelPressed(cell: ButtonCellOf<String>, row: ButtonRow) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func savePressed(cell: ButtonCellOf<String>, row: ButtonRow) {
        if let user = self.user {
            let alert = SCLAlertView().showWait("Updating profile", subTitle: "")
            var showWarning: Bool = false
            var warning: String = "Unable to save profile."
            var close: Bool = true

            let values = form.values()
            var userName: String?
            var firstName: String?
            var lastName: String?
            var email: String?
            var birthday: NSDate?

            let service = UserService()

            if let value = values["Username"] as? String {
                userName = value == user.userName ? nil : value

                if let userName = userName {
                    service.updateUsername(userName, user: user, completion: { result in
                        if !result {
                            showWarning = true
                            warning = "Username is already in use."
                        }

                        if service.outstandingRequestCount() == 0 {
                            self.setFormValues()
                            alert.close()
                            if showWarning {
                                SCLAlertView().showWarning("Warning", subTitle: warning)
                            } else {
                                SCLAlertView().showSuccess("Saved", subTitle: "", duration: 2.0)
                            }
                        }
                    })

                    close = false
                }
            }

            if let value = values["FirstName"] as? String {
                firstName = value == user.firstName ? nil : value
            }

            if let value = values["LastName"] as? String {
                lastName = value == user.lastName ? nil : value
            }

            if let value = values["Email"] as? String {
                email = value == user.email ? nil : value

                if let email = email {
                    service.updateEmail(email, user: user, completion: { result in
                        if !result {
                            showWarning = true
                            warning = "Email is already in use."
                        }

                        if service.outstandingRequestCount() == 0 {
                            self.setFormValues()
                            alert.close()
                            if showWarning {
                                SCLAlertView().showWarning("Warning", subTitle: warning)
                            } else {
                                SCLAlertView().showSuccess("Saved", subTitle: "", duration: 2.0)
                            }
                        }
                    })

                    close = false
                }
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
                service.updateProfile(firstName, lastName: lastName, birthday: birthday, user: user, completion: { result in
                    if !result {
                        showWarning = true
                    }

                    if service.outstandingRequestCount() == 0 {
                        self.setFormValues()
                        alert.close()
                        if showWarning {
                            SCLAlertView().showWarning("Warning", subTitle: warning)
                        } else {
                            SCLAlertView().showSuccess("Saved", subTitle: "", duration: 2.0)
                        }
                    }
                })

                close = false
            }

            if close {
                alert.close()
            }
        }
    }

    func setFormValues() {
        if let user = user {
            let birthday = (user.birthday != nil) ? user.birthday! : NSDate()
            let values: [String: Any?] = ["Username": user.userName, "FirstName": user.firstName, "LastName": user.lastName, "Email": user.email, "Birthday": birthday]
            self.form.setValues(values)
            self.tableView?.reloadData()
        }
    }

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        super.viewDidLoad()

        guard self.user != nil else {
            Log.info("Expected a user initiated via previous controller.")
            return
        }

        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let veView = UIVisualEffectView(effect: blurEffect)
        veView.frame = self.view.bounds
        self.view.backgroundColor = UIColor.clearColor()
        self.view.insertSubview(veView, atIndex: 0)
        self.tableView?.backgroundColor = UIColor.clearColor()

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
                $0.cellSetup({ cell, row in
                    cell.tintColor = UIColor.fablerOrangeColor()
                    if let size = cell.textLabel?.font.pointSize {
                        cell.textLabel?.font = UIFont.boldSystemFontOfSize(size)
                    }
                })
            }

        self.form +++= Section()
            <<< ButtonRow("Cancel") {
                $0.title = $0.tag
                $0.onCellSelection(self.cancelPressed)
                $0.cellSetup({ cell, row in cell.tintColor = UIColor.fablerOrangeColor()})
            }

        self.setFormValues()
    }
}
