-- Clinic Booking System Database

-- -----------------------------------------------------
-- Table `UserAccounts`

CREATE TABLE IF NOT EXISTS `UserAccounts` (
  `user_id` INT AUTO_INCREMENT PRIMARY KEY,
  `username` VARCHAR(100) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL COMMENT 'Store hashed passwords only',
  `email` VARCHAR(150) NOT NULL UNIQUE,
  `role_id` INT NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `last_login_at` TIMESTAMP NULL DEFAULT NULL,
  `is_active` BOOLEAN DEFAULT TRUE,
  CONSTRAINT `fk_useraccounts_role`
    FOREIGN KEY (`role_id`)
    REFERENCES `Roles` (`role_id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='User login and role management';

-- -----------------------------------------------------
-- Table `ClinicLocations`

-- Table `Patients`

CREATE TABLE IF NOT EXISTS `Patients` (
  `patient_id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NULL UNIQUE COMMENT 'Optional: Link to UserAccounts if patient can log in',
  `first_name` VARCHAR(100) NOT NULL,
  `last_name` VARCHAR(100) NOT NULL,
  `date_of_birth` DATE NULL,
  `gender` ENUM('Male', 'Female', 'Other', 'Prefer not to say') NULL,
  `address_line1` VARCHAR(255) NULL,
  `address_line2` VARCHAR(255) NULL,
  `city` VARCHAR(100) NULL,
  `state_province` VARCHAR(100) NULL,
  `postal_code` VARCHAR(20) NULL,
  `country` VARCHAR(50) NULL,
  `phone_number` VARCHAR(20) NULL,
  `email` VARCHAR(150) NULL UNIQUE COMMENT 'Patient contact email, might differ from login email',
  `medical_history_summary` TEXT NULL,
  `emergency_contact_name` VARCHAR(100) NULL,
  `emergency_contact_phone` VARCHAR(20) NULL,
  `registered_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_patients_user`
    FOREIGN KEY (`user_id`)
    REFERENCES `UserAccounts` (`user_id`)
    ON DELETE SET NULL -- If user account deleted, patient profile remains but unlinked
    ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Patient demographics and contact information';


-- -----------------------------------------------------
-- Table `DoctorAvailability`

CREATE TABLE IF NOT EXISTS `DoctorAvailability` (
  `availability_id` INT AUTO_INCREMENT PRIMARY KEY,
  `doctor_id` INT NOT NULL,
  `location_id` INT NOT NULL,
  `day_of_week` ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NOT NULL,
  `start_time` TIME NOT NULL,
  `end_time` TIME NOT NULL,
  `is_available` BOOLEAN DEFAULT TRUE,
  `notes` VARCHAR(255) NULL,
  CONSTRAINT `fk_availability_doctor`
    FOREIGN KEY (`doctor_id`)
    REFERENCES `Doctors` (`doctor_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_availability_location`
    FOREIGN KEY (`location_id`)
    REFERENCES `ClinicLocations` (`location_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  UNIQUE `uq_doctor_location_day_time` (`doctor_id`, `location_id`, `day_of_week`, `start_time`),
  CONSTRAINT `chk_end_time_after_start_time` CHECK (`end_time` > `start_time`)
) ENGINE=InnoDB COMMENT='Doctor working schedules and availability';

-- -----------------------------------------------------
-- Table `Appointments`

CREATE TABLE IF NOT EXISTS `Appointments` (
  `appointment_id` INT AUTO_INCREMENT PRIMARY KEY,
  `patient_id` INT NOT NULL,
  `doctor_id` INT NOT NULL,
  `service_id` INT NOT NULL,
  `location_id` INT NOT NULL,
  `appointment_datetime` DATETIME NOT NULL COMMENT 'Specific date and time of the appointment',
  `duration_minutes` INT NOT NULL COMMENT 'Actual duration, might be prefilled from service',
  `status` ENUM('Scheduled', 'Confirmed', 'CancelledByPatient', 'CancelledByClinic', 'Completed', 'NoShow') NOT NULL DEFAULT 'Scheduled',
  `notes_patient` TEXT NULL COMMENT 'Notes from patient during booking',
  `notes_clinic` TEXT NULL COMMENT 'Internal notes by clinic staff/doctor',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_appointments_patient`
    FOREIGN KEY (`patient_id`)
    REFERENCES `Patients` (`patient_id`)
    ON DELETE RESTRICT -- Don't delete appointment if patient exists, handle cancellation
    ON UPDATE CASCADE,
  CONSTRAINT `fk_appointments_doctor`
    FOREIGN KEY (`doctor_id`)
    REFERENCES `Doctors` (`doctor_id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT `fk_appointments_service`
    FOREIGN KEY (`service_id`)
    REFERENCES `Services` (`service_id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT `fk_appointments_location`
    FOREIGN KEY (`location_id`)
    REFERENCES `ClinicLocations` (`location_id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  UNIQUE `uq_doctor_time_slot` (`doctor_id`, `appointment_datetime`) COMMENT 'Prevent double booking for a doctor at the same time',
  UNIQUE `uq_patient_time_slot` (`patient_id`, `appointment_datetime`) COMMENT 'Prevent patient booking multiple appointments at same time'
) ENGINE=InnoDB COMMENT='Patient appointments with doctors for services';

-- -----------------------------------------------------
-- Table `MedicalRecords`

CREATE TABLE IF NOT EXISTS `MedicalRecords` (
  `record_id` INT AUTO_INCREMENT PRIMARY KEY,
  `appointment_id` INT NOT NULL UNIQUE COMMENT 'Each record is tied to one specific appointment',
  `patient_id` INT NOT NULL,
  `doctor_id` INT NOT NULL,
  `visit_date` DATE NOT NULL,
  `diagnosis` TEXT NULL,
  `treatment_plan` TEXT NULL,
  `doctor_notes` TEXT NULL,
  `vital_signs` VARCHAR(255) NULL COMMENT 'e.g., BP: 120/80, Temp: 37C',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_medicalrecords_appointment`
    FOREIGN KEY (`appointment_id`)
    REFERENCES `Appointments` (`appointment_id`)
    ON DELETE CASCADE -- If appointment is deleted, associated record is also deleted
    ON UPDATE CASCADE,
  CONSTRAINT `fk_medicalrecords_patient`
    FOREIGN KEY (`patient_id`)
    REFERENCES `Patients` (`patient_id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT `fk_medicalrecords_doctor`
    FOREIGN KEY (`doctor_id`)
    REFERENCES `Doctors` (`doctor_id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Patient medical records from visits';

-- -----------------------------------------------------
-- Table `Prescriptions`

CREATE TABLE IF NOT EXISTS `Prescriptions` (
  `prescription_id` INT AUTO_INCREMENT PRIMARY KEY,
  `medical_record_id` INT NOT NULL,
  `medication_name` VARCHAR(150) NOT NULL,
  `dosage` VARCHAR(100) NULL,
  `frequency` VARCHAR(100) NULL,
  `duration` VARCHAR(100) NULL COMMENT 'e.g., 7 days, 1 month',
  `instructions` TEXT NULL,
  `issue_date` DATE NOT NULL DEFAULT (CURDATE()),
  CONSTRAINT `fk_prescriptions_medicalrecord`
    FOREIGN KEY (`medical_record_id`)
    REFERENCES `MedicalRecords` (`record_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Medications prescribed to patients';

-- -----------------------------------------------------
-- Table `BillingInvoices`

CREATE TABLE IF NOT EXISTS `BillingInvoices` (
  `invoice_id` INT AUTO_INCREMENT PRIMARY KEY,
  `appointment_id` INT NOT NULL UNIQUE COMMENT 'Typically one invoice per billable appointment',
  `patient_id` INT NOT NULL,
  `issue_date` DATE NOT NULL DEFAULT (CURDATE()),
  `due_date` DATE NULL,
  `total_amount` DECIMAL(10,2) NOT NULL,
  `amount_paid` DECIMAL(10,2) DEFAULT 0.00,
  `payment_status` ENUM('Unpaid', 'PartiallyPaid', 'Paid', 'Overdue', 'Waived') NOT NULL DEFAULT 'Unpaid',
  `notes` TEXT NULL,
  CONSTRAINT `fk_billing_appointment`
    FOREIGN KEY (`appointment_id`)
    REFERENCES `Appointments` (`appointment_id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT `fk_billing_patient`
    FOREIGN KEY (`patient_id`)
    REFERENCES `Patients` (`patient_id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT `chk_amount_paid_not_greater_total` CHECK (`amount_paid` <= `total_amount`)
) ENGINE=InnoDB COMMENT='Invoices for services rendered';

-- -----------------------------------------------------
-- Table `Payments`

CREATE TABLE IF NOT EXISTS `Payments` (
  `payment_id` INT AUTO_INCREMENT PRIMARY KEY,
  `invoice_id` INT NOT NULL,
  `payment_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `amount` DECIMAL(10,2) NOT NULL,
  `payment_method` ENUM('Cash', 'CreditCard', 'DebitCard', 'BankTransfer', 'Insurance', 'Other') NOT NULL,
  `transaction_id` VARCHAR(100) NULL UNIQUE COMMENT 'For card/bank transactions',
  `notes` TEXT NULL,
  CONSTRAINT `fk_payments_invoice`
    FOREIGN KEY (`invoice_id`)
    REFERENCES `BillingInvoices` (`invoice_id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT `chk_payment_amount_positive` CHECK (`amount` > 0)
) ENGINE=InnoDB COMMENT='Records of payments made by patients';

-- -----------------------------------------------------
-- Junction Table: DoctorServices

CREATE TABLE IF NOT EXISTS `DoctorServices` (
  `doctor_id` INT NOT NULL,
  `service_id` INT NOT NULL,
  PRIMARY KEY (`doctor_id`, `service_id`),
  CONSTRAINT `fk_doctorservices_doctor`
    FOREIGN KEY (`doctor_id`)
    REFERENCES `Doctors` (`doctor_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_doctorservices_service`
    FOREIGN KEY (`service_id`)
    REFERENCES `Services` (`service_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Maps doctors to specific services they offer (M-M)';

CREATE TABLE IF NOT EXISTS `ClinicLocations` (
  `location_id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `address_line1` VARCHAR(255) NOT NULL,
  `address_line2` VARCHAR(255) NULL,
  `city` VARCHAR(100) NOT NULL,
  `state_province` VARCHAR(100) NOT NULL,
  `postal_code` VARCHAR(20) NOT NULL,
  `country` VARCHAR(50) NOT NULL,
  `phone_number` VARCHAR(20) NULL,
  `operating_hours` VARCHAR(255) NULL COMMENT 'e.g., Mon-Fri 9AM-5PM'
) ENGINE=InnoDB COMMENT='Physical locations of the clinic';

-- -----------------------------------------------------
-- Table `Specialties`

CREATE TABLE IF NOT EXISTS `Specialties` (
  `specialty_id` INT AUTO_INCREMENT PRIMARY KEY,
  `specialty_name` VARCHAR(100) NOT NULL UNIQUE,
  `description` TEXT NULL
) ENGINE=InnoDB COMMENT='Medical specialties of doctors';

-- -----------------------------------------------------
-- Table `Doctors`

CREATE TABLE IF NOT EXISTS `Doctors` (
  `doctor_id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL UNIQUE COMMENT 'Link to UserAccounts for login',
  `first_name` VARCHAR(100) NOT NULL,
  `last_name` VARCHAR(100) NOT NULL,
  `specialty_id` INT NULL,
  `phone_number` VARCHAR(20) NULL,
  `bio` TEXT NULL,
  `profile_picture_url` VARCHAR(255) NULL,
  `license_number` VARCHAR(50) NULL UNIQUE,
  CONSTRAINT `fk_doctors_user`
    FOREIGN KEY (`user_id`)
    REFERENCES `UserAccounts` (`user_id`)
    ON DELETE CASCADE -- If user account is deleted, doctor profile is removed
    ON UPDATE CASCADE,
  CONSTRAINT `fk_doctors_specialty`
    FOREIGN KEY (`specialty_id`)
    REFERENCES `Specialties` (`specialty_id`)
    ON DELETE SET NULL -- If specialty is removed, doctor's specialty becomes NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Doctor profiles and information';

-- -----------------------------------------------------