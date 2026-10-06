using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace KoreanTaxi.Migrations
{
    /// <inheritdoc />
    public partial class initial : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "backgroundhistories",
                columns: table => new
                {
                    backgroundhistoryid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    issuccess = table.Column<bool>(type: "boolean", nullable: false),
                    customerqueuecount = table.Column<int>(type: "integer", nullable: false),
                    driverqueuecount = table.Column<int>(type: "integer", nullable: false),
                    successamount = table.Column<int>(type: "integer", nullable: false),
                    erroramount = table.Column<int>(type: "integer", nullable: false),
                    process = table.Column<string>(type: "text", nullable: false),
                    error = table.Column<string>(type: "text", nullable: false),
                    createddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_backgroundhistories", x => x.backgroundhistoryid);
                });

            migrationBuilder.CreateTable(
                name: "companies",
                columns: table => new
                {
                    companyid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    name = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    phonenumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    contactname = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    address1 = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    address2 = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    city = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    state = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    zip = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    longitude = table.Column<decimal>(type: "numeric(9,6)", nullable: false),
                    latitude = table.Column<decimal>(type: "numeric(8,6)", nullable: false),
                    timezone = table.Column<int>(type: "integer", nullable: false),
                    createddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    modifieddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_companies", x => x.companyid);
                });

            migrationBuilder.CreateTable(
                name: "coupons",
                columns: table => new
                {
                    couponid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    customerid = table.Column<long>(type: "bigint", nullable: true),
                    code = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    amount = table.Column<decimal>(type: "numeric", nullable: false),
                    active = table.Column<bool>(type: "boolean", nullable: false),
                    createddate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_coupons", x => x.couponid);
                });

            migrationBuilder.CreateTable(
                name: "events",
                columns: table => new
                {
                    eventid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    eventstartdate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    eventenddate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    eventname = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    eventdescription = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_events", x => x.eventid);
                });

            migrationBuilder.CreateTable(
                name: "googlelocations",
                columns: table => new
                {
                    googlelocationid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    name = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    address = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    longitude = table.Column<decimal>(type: "numeric(9,6)", nullable: false),
                    latitude = table.Column<decimal>(type: "numeric(8,6)", nullable: false),
                    state = table.Column<int>(type: "integer", nullable: false),
                    locationtype = table.Column<int>(type: "integer", nullable: false),
                    createddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_googlelocations", x => x.googlelocationid);
                });

            migrationBuilder.CreateTable(
                name: "loginusers",
                columns: table => new
                {
                    loginuserid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    username = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    password = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    passwordhash = table.Column<byte[]>(type: "bytea", nullable: true),
                    passwordsalt = table.Column<byte[]>(type: "bytea", nullable: true),
                    refreshtoken = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    tokencreated = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    tokenexpires = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    role = table.Column<int>(type: "integer", nullable: false),
                    isactive = table.Column<bool>(type: "boolean", nullable: false),
                    lastlogindatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    createddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    modifieddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_loginusers", x => x.loginuserid);
                });

            migrationBuilder.CreateTable(
                name: "statedefaultlocations",
                columns: table => new
                {
                    statedefaultlocationid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    state = table.Column<int>(type: "integer", nullable: false),
                    longitude = table.Column<decimal>(type: "numeric(9,6)", nullable: false),
                    latitude = table.Column<decimal>(type: "numeric(8,6)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_statedefaultlocations", x => x.statedefaultlocationid);
                });

            migrationBuilder.CreateTable(
                name: "statefees",
                columns: table => new
                {
                    statefeeid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    fromstate = table.Column<int>(type: "integer", nullable: true),
                    tostate = table.Column<int>(type: "integer", nullable: true),
                    calculationmethod = table.Column<int>(type: "integer", nullable: false),
                    description = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    value = table.Column<decimal>(type: "numeric", nullable: false),
                    locationtype = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_statefees", x => x.statefeeid);
                });

            migrationBuilder.CreateTable(
                name: "companyoperatingstates",
                columns: table => new
                {
                    companyoperatingstateid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    companyid = table.Column<long>(type: "bigint", nullable: false),
                    fromstate = table.Column<int>(type: "integer", nullable: false),
                    tostate = table.Column<int>(type: "integer", nullable: true),
                    createddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_companyoperatingstates", x => x.companyoperatingstateid);
                    table.ForeignKey(
                        name: "fk_companyoperatingstates_companies_companyid",
                        column: x => x.companyid,
                        principalTable: "companies",
                        principalColumn: "companyid",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "companytripprices",
                columns: table => new
                {
                    companytrippriceid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    fromcity = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    tocity = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    companyid = table.Column<long>(type: "bigint", nullable: false),
                    price = table.Column<decimal>(type: "numeric", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_companytripprices", x => x.companytrippriceid);
                    table.ForeignKey(
                        name: "fk_companytripprices_companies_companyid",
                        column: x => x.companyid,
                        principalTable: "companies",
                        principalColumn: "companyid",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "companyfrequentlocations",
                columns: table => new
                {
                    companyfrequentlocationid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    companyid = table.Column<long>(type: "bigint", nullable: false),
                    googlelocationid = table.Column<long>(type: "bigint", nullable: false),
                    createddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_companyfrequentlocations", x => x.companyfrequentlocationid);
                    table.ForeignKey(
                        name: "fk_companyfrequentlocations_companies_companyid",
                        column: x => x.companyid,
                        principalTable: "companies",
                        principalColumn: "companyid",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_companyfrequentlocations_googlelocations_googlelocationid",
                        column: x => x.googlelocationid,
                        principalTable: "googlelocations",
                        principalColumn: "googlelocationid",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "companygooglelocations",
                columns: table => new
                {
                    companygooglelocationid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    name = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    googlelocationid = table.Column<long>(type: "bigint", nullable: false),
                    companyid = table.Column<long>(type: "bigint", nullable: true),
                    createddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_companygooglelocations", x => x.companygooglelocationid);
                    table.ForeignKey(
                        name: "fk_companygooglelocations_companies_companyid",
                        column: x => x.companyid,
                        principalTable: "companies",
                        principalColumn: "companyid",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_companygooglelocations_googlelocations_googlelocationid",
                        column: x => x.googlelocationid,
                        principalTable: "googlelocations",
                        principalColumn: "googlelocationid",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "companyusers",
                columns: table => new
                {
                    companyuserid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    companyid = table.Column<long>(type: "bigint", nullable: false),
                    loginuserid = table.Column<long>(type: "bigint", nullable: false),
                    name = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_companyusers", x => x.companyuserid);
                    table.ForeignKey(
                        name: "fk_companyusers_companies_companyid",
                        column: x => x.companyid,
                        principalTable: "companies",
                        principalColumn: "companyid",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_companyusers_loginusers_loginuserid",
                        column: x => x.loginuserid,
                        principalTable: "loginusers",
                        principalColumn: "loginuserid",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "customers",
                columns: table => new
                {
                    customerid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    firstname = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    lastname = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    email = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    phonenumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    loginuserid = table.Column<long>(type: "bigint", nullable: false),
                    stripecustomerid = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    isverified = table.Column<bool>(type: "boolean", nullable: false),
                    authnumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    point = table.Column<decimal>(type: "numeric", nullable: false),
                    language = table.Column<int>(type: "integer", nullable: false),
                    term1 = table.Column<bool>(type: "boolean", nullable: false),
                    term2 = table.Column<bool>(type: "boolean", nullable: false),
                    defaultcardid = table.Column<long>(type: "bigint", nullable: true),
                    timezone = table.Column<int>(type: "integer", nullable: false),
                    createddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_customers", x => x.customerid);
                    table.ForeignKey(
                        name: "fk_customers_loginusers_loginuserid",
                        column: x => x.loginuserid,
                        principalTable: "loginusers",
                        principalColumn: "loginuserid",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "drivers",
                columns: table => new
                {
                    driverid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    firstname = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    lastname = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    dob = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    email = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    phonenumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    companyid = table.Column<long>(type: "bigint", nullable: false),
                    loginuserid = table.Column<long>(type: "bigint", nullable: false),
                    drivernumber = table.Column<int>(type: "integer", nullable: false),
                    language = table.Column<int>(type: "integer", nullable: false),
                    tlcapproved = table.Column<bool>(type: "boolean", nullable: false),
                    isapptaxi = table.Column<bool>(type: "boolean", nullable: false),
                    createddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    isarchived = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    map = table.Column<string>(type: "character varying(25)", maxLength: 25, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_drivers", x => x.driverid);
                    table.ForeignKey(
                        name: "fk_drivers_companies_companyid",
                        column: x => x.companyid,
                        principalTable: "companies",
                        principalColumn: "companyid",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_drivers_loginusers_loginuserid",
                        column: x => x.loginuserid,
                        principalTable: "loginusers",
                        principalColumn: "loginuserid",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "customercards",
                columns: table => new
                {
                    customercardid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    customerid = table.Column<long>(type: "bigint", nullable: false),
                    paymentmethodid = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    last4 = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    expirationmonth = table.Column<int>(type: "integer", nullable: false),
                    expirationyear = table.Column<int>(type: "integer", nullable: false),
                    brand = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    isremoved = table.Column<bool>(type: "boolean", nullable: false),
                    createddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_customercards", x => x.customercardid);
                    table.ForeignKey(
                        name: "fk_customercards_customers_customerid",
                        column: x => x.customerid,
                        principalTable: "customers",
                        principalColumn: "customerid",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "customersavedlocations",
                columns: table => new
                {
                    customersavedlocationid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    customerid = table.Column<long>(type: "bigint", nullable: false),
                    googlelocationid = table.Column<long>(type: "bigint", nullable: false),
                    type = table.Column<int>(type: "integer", nullable: false),
                    createddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_customersavedlocations", x => x.customersavedlocationid);
                    table.ForeignKey(
                        name: "fk_customersavedlocations_customers_customerid",
                        column: x => x.customerid,
                        principalTable: "customers",
                        principalColumn: "customerid",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_customersavedlocations_googlelocations_googlelocationid",
                        column: x => x.googlelocationid,
                        principalTable: "googlelocations",
                        principalColumn: "googlelocationid",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "customersearchhistories",
                columns: table => new
                {
                    customersearchhistoryid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    customerid = table.Column<long>(type: "bigint", nullable: false),
                    googlelocationid = table.Column<long>(type: "bigint", nullable: false),
                    createddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_customersearchhistories", x => x.customersearchhistoryid);
                    table.ForeignKey(
                        name: "fk_customersearchhistories_customers_customerid",
                        column: x => x.customerid,
                        principalTable: "customers",
                        principalColumn: "customerid",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_customersearchhistories_googlelocations_googlelocationid",
                        column: x => x.googlelocationid,
                        principalTable: "googlelocations",
                        principalColumn: "googlelocationid",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "pointaddhistories",
                columns: table => new
                {
                    pointaddhistoryid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    pointtype = table.Column<int>(type: "integer", nullable: false),
                    amount = table.Column<decimal>(type: "numeric", nullable: false),
                    customerid = table.Column<long>(type: "bigint", nullable: false),
                    createddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_pointaddhistories", x => x.pointaddhistoryid);
                    table.ForeignKey(
                        name: "fk_pointaddhistories_customers_customerid",
                        column: x => x.customerid,
                        principalTable: "customers",
                        principalColumn: "customerid",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "taxis",
                columns: table => new
                {
                    taxiid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    color = table.Column<int>(type: "integer", nullable: false),
                    make = table.Column<int>(type: "integer", nullable: false),
                    model = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    licenseplate = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    size = table.Column<int>(type: "integer", nullable: false),
                    driverid = table.Column<long>(type: "bigint", nullable: true),
                    createddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_taxis", x => x.taxiid);
                    table.ForeignKey(
                        name: "fk_taxis_drivers_driverid",
                        column: x => x.driverid,
                        principalTable: "drivers",
                        principalColumn: "driverid",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "trips",
                columns: table => new
                {
                    tripid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    customerid = table.Column<long>(type: "bigint", nullable: true),
                    companyid = table.Column<long>(type: "bigint", nullable: true),
                    driverid = table.Column<long>(type: "bigint", nullable: true),
                    tripstatus = table.Column<int>(type: "integer", nullable: false),
                    pickuplocationid = table.Column<long>(type: "bigint", nullable: false),
                    dropofflocationid = table.Column<long>(type: "bigint", nullable: true),
                    calledtaxisize = table.Column<int>(type: "integer", nullable: true),
                    mileage = table.Column<decimal>(type: "numeric", nullable: false),
                    mileageamount = table.Column<decimal>(type: "numeric", nullable: false),
                    tollamount = table.Column<decimal>(type: "numeric", nullable: false),
                    smallstatefeeamount = table.Column<decimal>(type: "numeric", nullable: false),
                    largestatefeeamount = table.Column<decimal>(type: "numeric", nullable: false),
                    customerphonenumber = table.Column<string>(type: "text", nullable: false),
                    alcoholphonenumber = table.Column<string>(type: "text", nullable: false),
                    alcoholtripid = table.Column<long>(type: "bigint", nullable: true),
                    companytripamount = table.Column<decimal>(type: "numeric", nullable: false),
                    notes = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    triptype = table.Column<int>(type: "integer", nullable: false),
                    createddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    completedtime = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_trips", x => x.tripid);
                    table.ForeignKey(
                        name: "fk_trips_companies_companyid",
                        column: x => x.companyid,
                        principalTable: "companies",
                        principalColumn: "companyid",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_trips_customers_customerid",
                        column: x => x.customerid,
                        principalTable: "customers",
                        principalColumn: "customerid",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_trips_drivers_driverid",
                        column: x => x.driverid,
                        principalTable: "drivers",
                        principalColumn: "driverid",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_trips_googlelocations_dropofflocationid",
                        column: x => x.dropofflocationid,
                        principalTable: "googlelocations",
                        principalColumn: "googlelocationid",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_trips_googlelocations_pickuplocationid",
                        column: x => x.pickuplocationid,
                        principalTable: "googlelocations",
                        principalColumn: "googlelocationid",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "customerqueues",
                columns: table => new
                {
                    customerqueueid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    customerid = table.Column<long>(type: "bigint", nullable: true),
                    tripid = table.Column<long>(type: "bigint", nullable: false),
                    queuestatus = table.Column<int>(type: "integer", nullable: false),
                    companyid = table.Column<long>(type: "bigint", nullable: true),
                    createddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_customerqueues", x => x.customerqueueid);
                    table.ForeignKey(
                        name: "fk_customerqueues_companies_companyid",
                        column: x => x.companyid,
                        principalTable: "companies",
                        principalColumn: "companyid",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_customerqueues_customers_customerid",
                        column: x => x.customerid,
                        principalTable: "customers",
                        principalColumn: "customerid",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_customerqueues_trips_tripid",
                        column: x => x.tripid,
                        principalTable: "trips",
                        principalColumn: "tripid",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "driverqueues",
                columns: table => new
                {
                    driverqueueid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    driverid = table.Column<long>(type: "bigint", nullable: false),
                    queuestatus = table.Column<int>(type: "integer", nullable: false),
                    declinedcount = table.Column<int>(type: "integer", nullable: true),
                    longitude = table.Column<decimal>(type: "numeric(9,6)", nullable: false),
                    latitude = table.Column<decimal>(type: "numeric(8,6)", nullable: false),
                    tripid = table.Column<long>(type: "bigint", nullable: true),
                    customerqueueid = table.Column<long>(type: "bigint", nullable: true),
                    declinedtime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    createddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_driverqueues", x => x.driverqueueid);
                    table.ForeignKey(
                        name: "fk_driverqueues_drivers_driverid",
                        column: x => x.driverid,
                        principalTable: "drivers",
                        principalColumn: "driverid",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_driverqueues_trips_tripid",
                        column: x => x.tripid,
                        principalTable: "trips",
                        principalColumn: "tripid",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "driverratings",
                columns: table => new
                {
                    driverratingid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    driverid = table.Column<long>(type: "bigint", nullable: false),
                    customerid = table.Column<long>(type: "bigint", nullable: false),
                    rating = table.Column<int>(type: "integer", nullable: false),
                    tripid = table.Column<long>(type: "bigint", nullable: false),
                    createddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_driverratings", x => x.driverratingid);
                    table.ForeignKey(
                        name: "fk_driverratings_customers_customerid",
                        column: x => x.customerid,
                        principalTable: "customers",
                        principalColumn: "customerid",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_driverratings_drivers_driverid",
                        column: x => x.driverid,
                        principalTable: "drivers",
                        principalColumn: "driverid",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_driverratings_trips_tripid",
                        column: x => x.tripid,
                        principalTable: "trips",
                        principalColumn: "tripid",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "payments",
                columns: table => new
                {
                    paymentid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    cardamount = table.Column<decimal>(type: "numeric", nullable: false),
                    tipamount = table.Column<decimal>(type: "numeric", nullable: false),
                    paymentstatus = table.Column<int>(type: "integer", nullable: false),
                    paymentintentid = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    paymenttype = table.Column<int>(type: "integer", nullable: false),
                    pointamount = table.Column<decimal>(type: "numeric", nullable: false),
                    tripid = table.Column<long>(type: "bigint", nullable: false),
                    customercardid = table.Column<long>(type: "bigint", nullable: true),
                    createddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_payments", x => x.paymentid);
                    table.ForeignKey(
                        name: "fk_payments_customercards_customercardid",
                        column: x => x.customercardid,
                        principalTable: "customercards",
                        principalColumn: "customercardid",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_payments_trips_tripid",
                        column: x => x.tripid,
                        principalTable: "trips",
                        principalColumn: "tripid",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "trippricedetails",
                columns: table => new
                {
                    trippricedetailid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    statefeeid = table.Column<long>(type: "bigint", nullable: false),
                    tripid = table.Column<long>(type: "bigint", nullable: false),
                    smallamount = table.Column<decimal>(type: "numeric", nullable: false),
                    largeamount = table.Column<decimal>(type: "numeric", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_trippricedetails", x => x.trippricedetailid);
                    table.ForeignKey(
                        name: "fk_trippricedetails_statefees_statefeeid",
                        column: x => x.statefeeid,
                        principalTable: "statefees",
                        principalColumn: "statefeeid",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_trippricedetails_trips_tripid",
                        column: x => x.tripid,
                        principalTable: "trips",
                        principalColumn: "tripid",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "driverqueuerejectedcustomerqueues",
                columns: table => new
                {
                    driverqueuerejectedcustomerqueueid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    driverqueueid = table.Column<long>(type: "bigint", nullable: false),
                    customerqueueid = table.Column<long>(type: "bigint", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_driverqueuerejectedcustomerqueues", x => x.driverqueuerejectedcustomerqueueid);
                    table.ForeignKey(
                        name: "fk_driverqueuerejectedcustomerqueues_driverqueues_driverqueueid",
                        column: x => x.driverqueueid,
                        principalTable: "driverqueues",
                        principalColumn: "driverqueueid",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "ix_companyfrequentlocations_companyid",
                table: "companyfrequentlocations",
                column: "companyid");

            migrationBuilder.CreateIndex(
                name: "ix_companyfrequentlocations_googlelocationid",
                table: "companyfrequentlocations",
                column: "googlelocationid");

            migrationBuilder.CreateIndex(
                name: "ix_companygooglelocations_companyid_googlelocationid",
                table: "companygooglelocations",
                columns: new[] { "companyid", "googlelocationid" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_companygooglelocations_googlelocationid",
                table: "companygooglelocations",
                column: "googlelocationid",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_companygooglelocations_name",
                table: "companygooglelocations",
                column: "name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_companyoperatingstates_companyid",
                table: "companyoperatingstates",
                column: "companyid");

            migrationBuilder.CreateIndex(
                name: "ix_companyoperatingstates_fromstate",
                table: "companyoperatingstates",
                column: "fromstate");

            migrationBuilder.CreateIndex(
                name: "ix_companytripprices_companyid",
                table: "companytripprices",
                column: "companyid");

            migrationBuilder.CreateIndex(
                name: "ix_companyusers_companyid",
                table: "companyusers",
                column: "companyid");

            migrationBuilder.CreateIndex(
                name: "ix_companyusers_loginuserid",
                table: "companyusers",
                column: "loginuserid",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_coupons_code",
                table: "coupons",
                column: "code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_coupons_customerid",
                table: "coupons",
                column: "customerid");

            migrationBuilder.CreateIndex(
                name: "ix_customercards_customerid",
                table: "customercards",
                column: "customerid");

            migrationBuilder.CreateIndex(
                name: "ix_customerqueues_companyid",
                table: "customerqueues",
                column: "companyid");

            migrationBuilder.CreateIndex(
                name: "ix_customerqueues_createddatetime",
                table: "customerqueues",
                column: "createddatetime",
                descending: new bool[0]);

            migrationBuilder.CreateIndex(
                name: "ix_customerqueues_customerid",
                table: "customerqueues",
                column: "customerid",
                unique: true,
                filter: "CustomerID is not null");

            migrationBuilder.CreateIndex(
                name: "ix_customerqueues_queuestatus",
                table: "customerqueues",
                column: "queuestatus");

            migrationBuilder.CreateIndex(
                name: "ix_customerqueues_tripid",
                table: "customerqueues",
                column: "tripid",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_customers_loginuserid",
                table: "customers",
                column: "loginuserid",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_customers_phonenumber_isverified",
                table: "customers",
                columns: new[] { "phonenumber", "isverified" },
                unique: true,
                filter: "IsVerified IS TRUE");

            migrationBuilder.CreateIndex(
                name: "ix_customersavedlocations_createddatetime",
                table: "customersavedlocations",
                column: "createddatetime");

            migrationBuilder.CreateIndex(
                name: "ix_customersavedlocations_customerid",
                table: "customersavedlocations",
                column: "customerid");

            migrationBuilder.CreateIndex(
                name: "ix_customersavedlocations_customerid_googlelocationid",
                table: "customersavedlocations",
                columns: new[] { "customerid", "googlelocationid" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_customersavedlocations_googlelocationid",
                table: "customersavedlocations",
                column: "googlelocationid");

            migrationBuilder.CreateIndex(
                name: "ix_customersearchhistories_createddatetime",
                table: "customersearchhistories",
                column: "createddatetime");

            migrationBuilder.CreateIndex(
                name: "ix_customersearchhistories_customerid",
                table: "customersearchhistories",
                column: "customerid");

            migrationBuilder.CreateIndex(
                name: "ix_customersearchhistories_customerid_googlelocationid",
                table: "customersearchhistories",
                columns: new[] { "customerid", "googlelocationid" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_customersearchhistories_googlelocationid",
                table: "customersearchhistories",
                column: "googlelocationid");

            migrationBuilder.CreateIndex(
                name: "ix_driverqueuerejectedcustomerqueues_driverqueueid",
                table: "driverqueuerejectedcustomerqueues",
                column: "driverqueueid");

            migrationBuilder.CreateIndex(
                name: "ix_driverqueues_createddatetime",
                table: "driverqueues",
                column: "createddatetime",
                descending: new bool[0]);

            migrationBuilder.CreateIndex(
                name: "ix_driverqueues_customerqueueid",
                table: "driverqueues",
                column: "customerqueueid");

            migrationBuilder.CreateIndex(
                name: "ix_driverqueues_driverid",
                table: "driverqueues",
                column: "driverid",
                unique: true,
                filter: "DriverID is not null");

            migrationBuilder.CreateIndex(
                name: "ix_driverqueues_queuestatus",
                table: "driverqueues",
                column: "queuestatus");

            migrationBuilder.CreateIndex(
                name: "ix_driverqueues_tripid",
                table: "driverqueues",
                column: "tripid");

            migrationBuilder.CreateIndex(
                name: "ix_driverratings_customerid",
                table: "driverratings",
                column: "customerid");

            migrationBuilder.CreateIndex(
                name: "ix_driverratings_driverid",
                table: "driverratings",
                column: "driverid");

            migrationBuilder.CreateIndex(
                name: "ix_driverratings_tripid",
                table: "driverratings",
                column: "tripid");

            migrationBuilder.CreateIndex(
                name: "ix_drivers_companyid",
                table: "drivers",
                column: "companyid");

            migrationBuilder.CreateIndex(
                name: "ix_drivers_loginuserid",
                table: "drivers",
                column: "loginuserid",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_drivers_phonenumber",
                table: "drivers",
                column: "phonenumber");

            migrationBuilder.CreateIndex(
                name: "ix_events_eventstartdate_eventenddate",
                table: "events",
                columns: new[] { "eventstartdate", "eventenddate" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_googlelocations_name_address",
                table: "googlelocations",
                columns: new[] { "name", "address" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_loginusers_username",
                table: "loginusers",
                column: "username",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_payments_customercardid",
                table: "payments",
                column: "customercardid");

            migrationBuilder.CreateIndex(
                name: "ix_payments_paymentstatus",
                table: "payments",
                column: "paymentstatus");

            migrationBuilder.CreateIndex(
                name: "ix_payments_paymenttype",
                table: "payments",
                column: "paymenttype");

            migrationBuilder.CreateIndex(
                name: "ix_payments_tripid",
                table: "payments",
                column: "tripid",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_pointaddhistories_customerid",
                table: "pointaddhistories",
                column: "customerid");

            migrationBuilder.CreateIndex(
                name: "ix_statedefaultlocations_state",
                table: "statedefaultlocations",
                column: "state",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_statefees_fromstate",
                table: "statefees",
                column: "fromstate");

            migrationBuilder.CreateIndex(
                name: "ix_statefees_tostate",
                table: "statefees",
                column: "tostate");

            migrationBuilder.CreateIndex(
                name: "ix_taxis_driverid",
                table: "taxis",
                column: "driverid",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_trippricedetails_statefeeid",
                table: "trippricedetails",
                column: "statefeeid");

            migrationBuilder.CreateIndex(
                name: "ix_trippricedetails_tripid",
                table: "trippricedetails",
                column: "tripid");

            migrationBuilder.CreateIndex(
                name: "ix_trips_companyid",
                table: "trips",
                column: "companyid");

            migrationBuilder.CreateIndex(
                name: "ix_trips_completedtime",
                table: "trips",
                column: "completedtime");

            migrationBuilder.CreateIndex(
                name: "ix_trips_customerid",
                table: "trips",
                column: "customerid");

            migrationBuilder.CreateIndex(
                name: "ix_trips_driverid",
                table: "trips",
                column: "driverid");

            migrationBuilder.CreateIndex(
                name: "ix_trips_dropofflocationid",
                table: "trips",
                column: "dropofflocationid");

            migrationBuilder.CreateIndex(
                name: "ix_trips_pickuplocationid_dropofflocationid",
                table: "trips",
                columns: new[] { "pickuplocationid", "dropofflocationid" });

            migrationBuilder.CreateIndex(
                name: "ix_trips_tripstatus",
                table: "trips",
                column: "tripstatus");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "backgroundhistories");

            migrationBuilder.DropTable(
                name: "companyfrequentlocations");

            migrationBuilder.DropTable(
                name: "companygooglelocations");

            migrationBuilder.DropTable(
                name: "companyoperatingstates");

            migrationBuilder.DropTable(
                name: "companytripprices");

            migrationBuilder.DropTable(
                name: "companyusers");

            migrationBuilder.DropTable(
                name: "coupons");

            migrationBuilder.DropTable(
                name: "customerqueues");

            migrationBuilder.DropTable(
                name: "customersavedlocations");

            migrationBuilder.DropTable(
                name: "customersearchhistories");

            migrationBuilder.DropTable(
                name: "driverqueuerejectedcustomerqueues");

            migrationBuilder.DropTable(
                name: "driverratings");

            migrationBuilder.DropTable(
                name: "events");

            migrationBuilder.DropTable(
                name: "payments");

            migrationBuilder.DropTable(
                name: "pointaddhistories");

            migrationBuilder.DropTable(
                name: "statedefaultlocations");

            migrationBuilder.DropTable(
                name: "taxis");

            migrationBuilder.DropTable(
                name: "trippricedetails");

            migrationBuilder.DropTable(
                name: "driverqueues");

            migrationBuilder.DropTable(
                name: "customercards");

            migrationBuilder.DropTable(
                name: "statefees");

            migrationBuilder.DropTable(
                name: "trips");

            migrationBuilder.DropTable(
                name: "customers");

            migrationBuilder.DropTable(
                name: "drivers");

            migrationBuilder.DropTable(
                name: "googlelocations");

            migrationBuilder.DropTable(
                name: "companies");

            migrationBuilder.DropTable(
                name: "loginusers");
        }
    }
}
