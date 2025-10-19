CREATE TABLE "database_note" (
	"id" varchar(255) PRIMARY KEY NOT NULL,
	"userId" varchar(255) NOT NULL,
	"title" varchar(255) DEFAULT '' NOT NULL,
	"content" text DEFAULT '' NOT NULL,
	"createdAt" timestamp with time zone DEFAULT '2025-10-18T11:42:13.377Z' NOT NULL,
	"updatedAt" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "database_user" (
	"id" varchar(255) PRIMARY KEY NOT NULL,
	"name" varchar(255),
	"email" varchar(255),
	"emailVerified" timestamp with time zone,
	"image" varchar(255)
);
--> statement-breakpoint
ALTER TABLE "database_note" ADD CONSTRAINT "database_note_userId_database_user_id_fk" FOREIGN KEY ("userId") REFERENCES "public"."database_user"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "user_email_unique" ON "database_user" USING btree ("email");