using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace KoreanTaxi.Migrations
{
    /// <inheritdoc />
    public partial class custoemrPhoneNumberCompany : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "customerphonenumber",
                table: "trips",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<string>(
                name: "alcoholphonenumber",
                table: "trips",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.CreateTable(
                name: "companycustomerphonenumbers",
                columns: table => new
                {
                    companycustomerphonenumberid = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    googlelocationid = table.Column<long>(type: "bigint", nullable: false),
                    companyid = table.Column<long>(type: "bigint", nullable: false),
                    phonenumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    createddatetime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_companycustomerphonenumbers", x => x.companycustomerphonenumberid);
                    table.ForeignKey(
                        name: "fk_companycustomerphonenumbers_companies_companyid",
                        column: x => x.companyid,
                        principalTable: "companies",
                        principalColumn: "companyid",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_companycustomerphonenumbers_googlelocations_googlelocationid",
                        column: x => x.googlelocationid,
                        principalTable: "googlelocations",
                        principalColumn: "googlelocationid",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "ix_companycustomerphonenumbers_companyid",
                table: "companycustomerphonenumbers",
                column: "companyid");

            migrationBuilder.CreateIndex(
                name: "ix_companycustomerphonenumbers_googlelocationid",
                table: "companycustomerphonenumbers",
                column: "googlelocationid");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "companycustomerphonenumbers");

            migrationBuilder.AlterColumn<string>(
                name: "customerphonenumber",
                table: "trips",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<string>(
                name: "alcoholphonenumber",
                table: "trips",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(50)",
                oldMaxLength: 50);
        }
    }
}
