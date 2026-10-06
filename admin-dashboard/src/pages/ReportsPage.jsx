import { Helmet } from 'react-helmet-async';
import { filter } from 'lodash';
import { useState, useEffect } from 'react';
import {
  Card,
  Table,
  Stack,
  Paper,
  TableRow,
  TableBody,
  TableCell,
  Container,
  Typography,
  TableContainer,
  TablePagination,
} from '@mui/material';
import Scrollbar from '../components/scrollbar';
import { ListHead, ListToolbar } from '../sections/@dashboard/user';

import apiService from '../components/apiService/apiService';
import userStore from '../store/userStore';
import hydrationStore from '../store/hydrationStore';

const TABLE_HEAD = [
  { id: 'driverId', label: '기사번호', alignRight: false },
  { id: 'firstName', label: '이름', alignRight: false },
  { id: 'mileage', label: '마일리지', alignRight: false },
  { id: 'tripAmount', label: '앱 택시 수익', alignRight: false },
  { id: 'taxAmount', label: '택스', alignRight: false },
  { id: 'tipAmount', label: '팁', alignRight: false },
  { id: 'tripCount', label: '현금 운행 횟수', alignRight: false },
  { id: 'totalAmoount', label: '실수령액', alignRight: false },
];

function descendingComparator(a, b, orderBy) {
  if (b[orderBy] < a[orderBy]) {
    return -1;
  }
  if (b[orderBy] > a[orderBy]) {
    return 1;
  }
  return 0;
}

function getComparator(order, orderBy) {
  return order === 'desc'
    ? (a, b) => descendingComparator(a, b, orderBy)
    : (a, b) => -descendingComparator(a, b, orderBy);
}

function applySortFilter(array, comparator, query) {
  const stabilizedThis = array.map((el, index) => [el, index]);
  stabilizedThis.sort((a, b) => {
    const order = comparator(a[0], b[0]);
    if (order !== 0) return order;
    return a[1] - b[1];
  });
  if (query) {
    return filter(array, (_report) => _report.firstName.toLowerCase().indexOf(query.toLowerCase()) !== -1);
  }
  return stabilizedThis.map((el) => el[0]);
}

export default function ReportsPage({ setIsLoading, setSnackBarMessage }) {
  const [page, setPage] = useState(0);

  const [order, setOrder] = useState('asc');

  const [orderBy, setOrderBy] = useState('reportId');

  const [filterName, setFilterName] = useState('');

  const [rowsPerPage, setRowsPerPage] = useState(5);

  const [reports, setReports] = useState([]);

  const company = hydrationStore(userStore, (state) => state.company);

  const jwtToken = hydrationStore(userStore, (state) => state.jwtToken);

  const [totalMileage, setTotalMileage] = useState(0);

  const [totalAmount, setTotalAmount] = useState(0);

  const [totalRides, setTotalRides] = useState(0);

  const getReports = async () => {
    setIsLoading(true);
    const response = await apiService().get(`/Report/GetCompanyReports`, {
      headers: {
        Authorization: `Bearer ${jwtToken}`,
        'Content-Type': 'application/json',
      },
    });
    if (response !== null && response.status === 200) {
      setReports(response.data);
      setIsLoading(false);
      setTotalAmount(response.data.reduce((acc, curr) => acc + curr.totalAmount, 0));
      setTotalMileage(response.data.reduce((acc, curr) => acc + curr.mileage, 0));
      setTotalRides(response.data.reduce((acc, curr) => acc + curr.tripCount, 0));
    }
  };

  useEffect(() => {
    if (company && jwtToken) {
      getReports();
    }
  }, [company]);

  const handleRequestSort = (event, property) => {
    const isAsc = orderBy === property && order === 'asc';
    setOrder(isAsc ? 'desc' : 'asc');
    setOrderBy(property);
  };

  const handleChangePage = (event, newPage) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event) => {
    setPage(0);
    setRowsPerPage(parseInt(event.target.value, 10));
  };

  const handleFilterByName = (event) => {
    setPage(0);
    setFilterName(event.target.value);
  };

  const emptyRows = page > 0 ? Math.max(0, (1 + page) * rowsPerPage - reports.length) : 0;

  const filteredUsers = applySortFilter(reports, getComparator(order, orderBy), filterName);

  const isNotFound = !filteredUsers.length && !!filterName;

  return (
    <>
      <Helmet>
        <title> Reports | Hanin Taxi </title>
      </Helmet>
      <Container maxWidth={false}>
        <Stack direction="row" alignItems="center" justifyContent="space-between" mb={5}>
          <Typography variant="h4" gutterBottom>
            Reports
          </Typography>
        </Stack>
        <Card>
          <ListToolbar filterName={filterName} onFilterName={handleFilterByName} placeholder="reports" />
          <Scrollbar>
            <TableContainer sx={{ minWidth: 800 }}>
              <Table>
                <ListHead
                  order={order}
                  orderBy={orderBy}
                  headLabel={TABLE_HEAD}
                  rowCount={reports.length}
                  onRequestSort={handleRequestSort}
                  checkbox={false}
                />
                <TableBody>
                  {filteredUsers.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage).map((row) => {
                    const { driverID, firstName, mileage, tripAmount, taxAmount, tipAmount, totalAmount, tripCount } =
                      row;
                    return (
                      <TableRow hover key={driverID} tabIndex={-1}>
                        <TableCell align="left" sx={{ whiteSpace: 'nowrap' }}>
                          {driverID}
                        </TableCell>
                        <TableCell align="left" sx={{ whiteSpace: 'nowrap' }}>
                          {firstName}
                        </TableCell>
                        <TableCell align="left" sx={{ whiteSpace: 'nowrap' }}>
                          {`${mileage} mile`}
                        </TableCell>
                        <TableCell align="left" sx={{ whiteSpace: 'nowrap' }}>
                          {`$${tripAmount}`}
                        </TableCell>
                        <TableCell align="left" sx={{ whiteSpace: 'nowrap' }}>
                          {`$${taxAmount}`}
                        </TableCell>
                        <TableCell align="left" sx={{ whiteSpace: 'nowrap' }}>
                          {`$${tipAmount}`}
                        </TableCell>
                        <TableCell align="left" sx={{ whiteSpace: 'nowrap' }}>
                          {`${tripCount} trips`}
                        </TableCell>
                        <TableCell align="left" sx={{ whiteSpace: 'nowrap' }}>
                          {`$${totalAmount}`}
                        </TableCell>
                      </TableRow>
                    );
                  })}
                  {!filterName && (
                    <TableRow>
                      <TableCell colSpan={4} />
                      <TableCell align="left">
                        <Typography>{`Totals : `}</Typography>
                      </TableCell>
                      <TableCell align="left">
                        <Typography>{`${totalMileage} miles`}</Typography>
                      </TableCell>
                      <TableCell align="left">
                        <Typography>{`$${totalAmount}`}</Typography>
                      </TableCell>
                      <TableCell align="left">
                        <Typography>{`${totalRides} trips`}</Typography>
                      </TableCell>
                    </TableRow>
                  )}
                  {emptyRows > 0 && (
                    <TableRow style={{ height: 53 * emptyRows }}>
                      <TableCell colSpan={7} />
                    </TableRow>
                  )}
                </TableBody>
                {isNotFound && (
                  <TableBody>
                    <TableRow>
                      <TableCell align="center" colSpan={12} sx={{ py: 3 }}>
                        <Paper
                          sx={{
                            textAlign: 'center',
                          }}
                        >
                          <Typography variant="h6" paragraph>
                            Not found
                          </Typography>
                          <Typography variant="body2">
                            No results found for &nbsp;
                            <strong>&quot;{filterName}&quot;</strong>.
                            <br /> Try checking for typos or using complete words.
                          </Typography>
                        </Paper>
                      </TableCell>
                    </TableRow>
                  </TableBody>
                )}
              </Table>
            </TableContainer>
          </Scrollbar>
          <TablePagination
            rowsPerPageOptions={[5, 10, 25]}
            component="div"
            count={reports.length}
            rowsPerPage={rowsPerPage}
            page={page}
            onPageChange={handleChangePage}
            onRowsPerPageChange={handleChangeRowsPerPage}
          />
        </Card>
      </Container>
    </>
  );
}
