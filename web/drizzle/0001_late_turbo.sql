CREATE TYPE "public"."task_status" AS ENUM('unprocessed', 'active', 'completed', 'waiting');--> statement-breakpoint
CREATE TABLE "database_project" (
	"id" varchar(255) PRIMARY KEY NOT NULL,
	"userId" varchar(255) NOT NULL,
	"name" varchar(255) NOT NULL,
	"rootTaskId" varchar(255),
	"createdAt" timestamp with time zone DEFAULT now() NOT NULL,
	"updatedAt" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "database_task_children" (
	"id" varchar(255) PRIMARY KEY NOT NULL,
	"taskId" varchar(255) NOT NULL,
	"childId" varchar(255) NOT NULL,
	"createdAt" timestamp with time zone DEFAULT now() NOT NULL,
	"updatedAt" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "database_task" (
	"id" varchar(255) PRIMARY KEY NOT NULL,
	"userId" varchar(255) NOT NULL,
	"projectId" varchar(255) NOT NULL,
	"name" varchar(255) NOT NULL,
	"date" timestamp with time zone,
	"status" "task_status" DEFAULT 'unprocessed' NOT NULL,
	"priority" varchar(50),
	"parentId" varchar(255),
	"createdAt" timestamp with time zone DEFAULT now() NOT NULL,
	"updatedAt" timestamp with time zone
);
--> statement-breakpoint
ALTER TABLE "database_note" ALTER COLUMN "createdAt" SET DEFAULT '2025-10-19T02:08:33.869Z';--> statement-breakpoint
ALTER TABLE "database_project" ADD CONSTRAINT "database_project_userId_database_user_id_fk" FOREIGN KEY ("userId") REFERENCES "public"."database_user"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "database_task_children" ADD CONSTRAINT "database_task_children_taskId_database_task_id_fk" FOREIGN KEY ("taskId") REFERENCES "public"."database_task"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "database_task_children" ADD CONSTRAINT "database_task_children_childId_database_task_id_fk" FOREIGN KEY ("childId") REFERENCES "public"."database_task"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "database_task" ADD CONSTRAINT "database_task_userId_database_user_id_fk" FOREIGN KEY ("userId") REFERENCES "public"."database_user"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "database_task" ADD CONSTRAINT "database_task_projectId_database_project_id_fk" FOREIGN KEY ("projectId") REFERENCES "public"."database_project"("id") ON DELETE no action ON UPDATE no action;