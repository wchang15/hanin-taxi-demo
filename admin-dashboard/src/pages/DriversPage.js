import { Helmet } from 'react-helmet-async';
import { filter } from 'lodash';
import { useEffect, useState } from 'react';
import {
  Card,
  Table,
  Stack,
  Paper,
  Button,
  Popover,
  Checkbox,
  TableRow,
  MenuItem,
  TableBody,
  TableCell,
  Container,
  Typography,
  IconButton,
  TableContainer,
  TablePagination,
} from '@mui/material';
import apiService from '../components/apiService/apiService';
import Iconify from '../components/iconify';
import Scrollbar from '../components/scrollbar';
import { ListHead, ListToolbar } from '../sections/@dashboard/user';
import { Sizes, Languages, TaxiColor, TaxiManufacturer } from '../_mock/user';
import CreateDriverModal from '../components/drivers/CreateDriverModal';
import EditDriverModal from '../components/drivers/EditDriverModal';
import userStore from '../store/userStore';
import hydrationStore from '../store/hydrationStore';

const TABLE_HEAD = [
  { id: 'driverNumber', label: '번호', alignRight: false },
  { id: 'firstName', label: '성함', alignRight: false },
  { id: 'email', label: '이메일', alignRight: false },
  { id: 'phoneNumber', label: '핸드폰 번호', alignRight: false },
  { id: 'color', label: '색상', alignRight: false },
  { id: 'make', label: '브랜드', alignRight: false },
  { id: 'size', label: '사이즈', alignRight: false },
  { id: 'model', label: '모델명', alignRight: false },
  { id: 'licensePlate', label: '차량번호', alignRight: false },
  { id: 'language', label: '언어', alignRight: false },
  { id: '' },
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
    return filter(array, (_user) => _user.firstName.toLowerCase().indexOf(query.toLowerCase()) !== -1);
  }
  return stabilizedThis.map((el) => el[0]);
}

export default function DriversPage({ setIsLoading, setSnackBarMessage }) {
  const [open, setOpen] = useState(null);

  const [page, setPage] = useState(0);

  const [order, setOrder] = useState('asc');

  const [selected, setSelected] = useState([]);

  const [orderBy, setOrderBy] = useState('id');

  const [filterName, setFilterName] = useState('');

  const [rowsPerPage, setRowsPerPage] = useState(5);

  const [editModal, setEditModal] = useState(false);

  const [createModal, setCreateModal] = useState(false);

  const [row, setRow] = useState();

  const [drivers, setDrivers] = useState([]);

  const [update, setUpdate] = useState(false);

  const getDrivers = async () => {
    setIsLoading(true);
    if (company && jwtToken) {
      const response = await apiService().get(`/Driver/GetCompanyDrivers`, {
        headers: {
          Authorization: `Bearer ${jwtToken}`,
          'Content-Type': 'application/json',
        },
      });
      if (response !== null && response.status === 200) {
        const data = response.data;
        console.log(data);
        setDrivers(data);
        setIsLoading(false);
      }
    }
  };

  const jwtToken = hydrationStore(userStore, (state) => state.jwtToken);

  const company = hydrationStore(userStore, (state) => state.company);

  useEffect(() => {
    getDrivers();
  }, [update, company]);

  const handleOpenMenu = (event) => {
    setOpen(event.currentTarget);
  };

  const handleCloseMenu = () => {
    setOpen(null);
  };

  const handleDelete = async () => {
    if (jwtToken) {
      await apiService()
        .post(`/Driver/ArchiveDriver?id=${row.id}`, null, {
          headers: {
            Authorization: `Bearer ${jwtToken}`,
            'Content-Type': 'application/json',
          },
        })
        .then((response) => {
          const driverName = response.data;
          setSnackBarMessage(`Driver ${driverName} has been successfully deleted`);
          setUpdate(!update);
        })
        .catch((error) => {
          console.log(error);
        });
      setUpdate(!update);
    }
  };

  const handleSelectedDelete = async () => {
    if (jwtToken) {
      const driverIds = selected.map((str) => Number(str));
      await apiService()
        .post(`/Driver/ArchiveDrivers`, driverIds, {
          headers: {
            Authorization: `Bearer ${jwtToken}`,
            'Content-Type': 'application/json',
          },
        })
        .then(() => {
          setSnackBarMessage(`${selected.length} selected driver has been successfully deleted`);
          setSelected([]);
          setUpdate(!update);
        })
        .catch((error) => {
          console.log(error);
        });
      setUpdate(!update);
    }
  };

  const handleRequestSort = (event, property) => {
    const isAsc = orderBy === property && order === 'asc';
    setOrder(isAsc ? 'desc' : 'asc');
    setOrderBy(property);
  };

  const handleSelectAllClick = (event) => {
    if (event.target.checked) {
      const newSelecteds = drivers.map((n) => n.id);
      setSelected(newSelecteds);
      return;
    }
    setSelected([]);
  };

  const handleClick = (event, id) => {
    const selectedIndex = selected.indexOf(id);
    let newSelected = [];
    if (selectedIndex === -1) {
      newSelected = newSelected.concat(selected, id);
    } else if (selectedIndex === 0) {
      newSelected = newSelected.concat(selected.slice(1));
    } else if (selectedIndex === selected.length - 1) {
      newSelected = newSelected.concat(selected.slice(0, -1));
    } else if (selectedIndex > 0) {
      newSelected = newSelected.concat(selected.slice(0, selectedIndex), selected.slice(selectedIndex + 1));
    }
    setSelected(newSelected);
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

  const emptyRows = page > 0 ? Math.max(0, (1 + page) * rowsPerPage - drivers.length) : 0;

  const filteredUsers = applySortFilter(drivers, getComparator(order, orderBy), filterName);

  const isNotFound = !filteredUsers.length && !!filterName;

  return (
    <>
      <Helmet>
        <title> Drivers | Hanin Taxi </title>
      </Helmet>
      <Container maxWidth={false}>
        <Stack direction="row" alignItems="center" justifyContent="space-between" mb={5}>
          <Typography variant="h4" gutterBottom>
            기사님
          </Typography>
          <Button
            variant="contained"
            onClick={() => {
              setCreateModal(true);
            }}
            startIcon={<Iconify icon="eva:plus-fill" />}
            sx={{ color: 'white' }}
          >
            기사님 추가
          </Button>
        </Stack>
        <Card>
          <ListToolbar
            numSelected={selected.length}
            filterName={filterName}
            onFilterName={handleFilterByName}
            placeholder="drivers"
            onDelete={handleSelectedDelete}
          />
          <Scrollbar>
            <TableContainer sx={{ minWidth: 800 }}>
              <Table>
                <ListHead
                  order={order}
                  orderBy={orderBy}
                  headLabel={TABLE_HEAD}
                  rowCount={drivers.length}
                  numSelected={selected.length}
                  onRequestSort={handleRequestSort}
                  onSelectAllClick={handleSelectAllClick}
                />
                <TableBody>
                  {filteredUsers.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage).map((row) => {
                    const {
                      id,
                      account,
                      driverNumber,
                      firstName,
                      email,
                      phoneNumber,
                      color,
                      make,
                      size,
                      model,
                      licensePlate,
                      language,
                    } = row;
                    const selectedUser = selected.indexOf(id) !== -1;
                    return (
                      <TableRow hover key={id} tabIndex={-1} role="checkbox" selected={selectedUser}>
                        <TableCell padding="checkbox">
                          <Checkbox checked={selectedUser} onChange={(event) => handleClick(event, id)} />
                        </TableCell>
                        <TableCell align="left" sx={{ whiteSpace: 'nowrap' }}>
                          {driverNumber}
                        </TableCell>
                        <TableCell align="left" sx={{ whiteSpace: 'nowrap' }}>
                          {firstName}
                        </TableCell>
                        <TableCell align="left" sx={{ whiteSpace: 'nowrap' }}>
                          {email}
                        </TableCell>
                        <TableCell align="left" sx={{ whiteSpace: 'nowrap' }}>
                          {phoneNumber}
                        </TableCell>
                        <TableCell align="left" sx={{ whiteSpace: 'nowrap' }}>
                          {TaxiColor.find((item) => item.value === color).label}
                        </TableCell>
                        <TableCell align="left" sx={{ whiteSpace: 'nowrap' }}>
                          {TaxiManufacturer.find((item) => item.value === make).label}
                        </TableCell>
                        <TableCell align="left" sx={{ whiteSpace: 'nowrap' }}>
                          {Sizes.find((item) => item.value === size).label}
                        </TableCell>
                        <TableCell align="left" sx={{ whiteSpace: 'nowrap' }}>
                          {model}
                        </TableCell>
                        <TableCell align="left" sx={{ whiteSpace: 'nowrap' }}>
                          {licensePlate}
                        </TableCell>
                        <TableCell align="left" sx={{ whiteSpace: 'nowrap' }}>
                          {Languages.find((item) => item.value === language).label}
                        </TableCell>
                        <TableCell align="right">
                          <IconButton
                            size="large"
                            color="inherit"
                            onClick={(e) => {
                              handleOpenMenu(e);
                              setRow(row);
                            }}
                          >
                            <Iconify icon={'eva:more-vertical-fill'} />
                          </IconButton>
                        </TableCell>
                      </TableRow>
                    );
                  })}
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
            count={drivers.length}
            rowsPerPage={rowsPerPage}
            page={page}
            onPageChange={handleChangePage}
            onRowsPerPageChange={handleChangeRowsPerPage}
          />
        </Card>
      </Container>
      <Popover
        open={Boolean(open)}
        anchorEl={open}
        onClose={handleCloseMenu}
        anchorOrigin={{ vertical: 'top', horizontal: 'left' }}
        transformOrigin={{ vertical: 'top', horizontal: 'right' }}
        PaperProps={{
          sx: {
            p: 1,
            width: 140,
            '& .MuiMenuItem-root': {
              px: 1,
              typography: 'body2',
              borderRadius: 0.75,
            },
          },
        }}
      >
        <MenuItem
          onClick={() => {
            handleCloseMenu();
            setEditModal(true);
          }}
        >
          <Iconify icon={'eva:edit-fill'} sx={{ mr: 2 }} />
          수정
        </MenuItem>
        <MenuItem
          sx={{ color: 'error.main' }}
          onClick={() => {
            handleCloseMenu();
            handleDelete();
          }}
        >
          <Iconify icon={'eva:trash-2-outline'} sx={{ mr: 2 }} />
          삭제
        </MenuItem>
      </Popover>
      <CreateDriverModal
        setSnackBarMessage={setSnackBarMessage}
        open={createModal}
        handleClose={() => setCreateModal(false)}
        update={update}
        setUpdate={setUpdate}
      />
      <EditDriverModal
        setSnackBarMessage={setSnackBarMessage}
        open={editModal}
        handleClose={() => setEditModal(false)}
        row={row}
        update={update}
        setUpdate={setUpdate}
      />
    </>
  );
}
